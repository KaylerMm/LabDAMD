const grpc = require('@grpc/grpc-js');

// gRPC Error Codes mapping
const ErrorCodes = {
  OK: 0,
  CANCELLED: 1,
  UNKNOWN: 2,
  INVALID_ARGUMENT: 3,
  DEADLINE_EXCEEDED: 4,
  NOT_FOUND: 5,
  ALREADY_EXISTS: 6,
  PERMISSION_DENIED: 7,
  RESOURCE_EXHAUSTED: 8,
  FAILED_PRECONDITION: 9,
  ABORTED: 10,
  OUT_OF_RANGE: 11,
  UNIMPLEMENTED: 12,
  INTERNAL: 13,
  UNAVAILABLE: 14,
  DATA_LOSS: 15,
  UNAUTHENTICATED: 16
};

class GrpcError extends Error {
  constructor(code, message, details = null) {
    super(message);
    this.code = code;
    this.details = details;
    this.name = 'GrpcError';
  }
}

// Error handling interceptor for gRPC clients
function createErrorInterceptor() {
  return (options, nextCall) => {
    return new Proxy(nextCall(options), {
      get(target, property, receiver) {
        if (property === 'start') {
          return function(metadata, listener, next) {
            const wrappedListener = {
              onReceiveMetadata: listener.onReceiveMetadata?.bind(listener),
              onReceiveMessage: listener.onReceiveMessage?.bind(listener),
              onReceiveStatus: (status) => {
                if (status.code !== ErrorCodes.OK) {
                  // Log error for monitoring
                  console.error(`gRPC Error [${status.code}]: ${status.details}`, {
                    method: options.method_definition.path,
                    metadata: metadata.getMap(),
                    timestamp: new Date().toISOString()
                  });
                  
                  // Transform error for better client handling
                  const transformedError = transformGrpcError(status);
                  listener.onReceiveStatus?.(transformedError);
                } else {
                  listener.onReceiveStatus?.(status);
                }
              }
            };
            
            target.start(metadata, wrappedListener, next);
          };
        }
        return Reflect.get(target, property, receiver);
      }
    });
  };
}

// Server-side error handling interceptor
function serverErrorInterceptor(call, callback, next) {
  try {
    next();
  } catch (error) {
    console.error('gRPC Server Error:', {
      error: error.message,
      stack: error.stack,
      method: call.getPath(),
      timestamp: new Date().toISOString(),
      metadata: call.metadata.getMap()
    });
    
    const grpcError = transformToGrpcError(error);
    callback(grpcError);
  }
}

// Transform JavaScript errors to gRPC errors
function transformToGrpcError(error) {
  if (error instanceof GrpcError) {
    return error;
  }
  
  // Map common errors to gRPC codes
  if (error.name === 'ValidationError') {
    return new GrpcError(ErrorCodes.INVALID_ARGUMENT, error.message);
  }
  
  if (error.name === 'NotFoundError' || error.message.includes('not found')) {
    return new GrpcError(ErrorCodes.NOT_FOUND, error.message);
  }
  
  if (error.name === 'UnauthorizedError') {
    return new GrpcError(ErrorCodes.UNAUTHENTICATED, error.message);
  }
  
  if (error.name === 'ForbiddenError') {
    return new GrpcError(ErrorCodes.PERMISSION_DENIED, error.message);
  }
  
  if (error.name === 'ConflictError') {
    return new GrpcError(ErrorCodes.ALREADY_EXISTS, error.message);
  }
  
  // Default to internal error
  return new GrpcError(ErrorCodes.INTERNAL, 'Internal server error');
}

// Transform gRPC errors for better client handling
function transformGrpcError(status) {
  const errorMap = {
    [ErrorCodes.INVALID_ARGUMENT]: 'Bad Request',
    [ErrorCodes.NOT_FOUND]: 'Resource Not Found',
    [ErrorCodes.UNAUTHENTICATED]: 'Authentication Required',
    [ErrorCodes.PERMISSION_DENIED]: 'Access Denied',
    [ErrorCodes.ALREADY_EXISTS]: 'Resource Already Exists',
    [ErrorCodes.UNAVAILABLE]: 'Service Unavailable',
    [ErrorCodes.INTERNAL]: 'Internal Server Error'
  };
  
  return {
    ...status,
    message: errorMap[status.code] || status.details || 'Unknown Error'
  };
}

// Express error handling middleware
function expressErrorHandler(err, req, res, next) {
  console.error('Express Error:', {
    error: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    timestamp: new Date().toISOString()
  });
  
  // Handle gRPC errors from downstream services
  if (err.code && typeof err.code === 'number') {
    const httpStatusMap = {
      [ErrorCodes.INVALID_ARGUMENT]: 400,
      [ErrorCodes.UNAUTHENTICATED]: 401,
      [ErrorCodes.PERMISSION_DENIED]: 403,
      [ErrorCodes.NOT_FOUND]: 404,
      [ErrorCodes.ALREADY_EXISTS]: 409,
      [ErrorCodes.UNAVAILABLE]: 503,
      [ErrorCodes.INTERNAL]: 500
    };
    
    const status = httpStatusMap[err.code] || 500;
    return res.status(status).json({
      error: err.message || 'An error occurred',
      code: err.code
    });
  }
  
  // Handle other errors
  const status = err.status || err.statusCode || 500;
  res.status(status).json({
    error: err.message || 'Internal Server Error'
  });
}

// Retry mechanism for transient failures
async function withRetry(operation, maxRetries = 3, baseDelay = 1000) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (attempt === maxRetries) {
        throw error;
      }
      
      // Only retry on transient errors
      if (error.code === ErrorCodes.UNAVAILABLE || 
          error.code === ErrorCodes.DEADLINE_EXCEEDED ||
          error.code === ErrorCodes.RESOURCE_EXHAUSTED) {
        
        const delay = baseDelay * Math.pow(2, attempt - 1); // Exponential backoff
        console.log(`Retrying operation in ${delay}ms (attempt ${attempt}/${maxRetries})`);
        await new Promise(resolve => setTimeout(resolve, delay));
      } else {
        throw error; // Don't retry non-transient errors
      }
    }
  }
}

// Circuit breaker implementation
class CircuitBreaker {
  constructor(options = {}) {
    this.failureThreshold = options.failureThreshold || 5;
    this.resetTimeout = options.resetTimeout || 60000; // 1 minute
    this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
    this.failures = 0;
    this.nextAttempt = Date.now();
  }
  
  async execute(operation) {
    if (this.state === 'OPEN') {
      if (Date.now() < this.nextAttempt) {
        throw new GrpcError(ErrorCodes.UNAVAILABLE, 'Circuit breaker is OPEN');
      }
      this.state = 'HALF_OPEN';
    }
    
    try {
      const result = await operation();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }
  
  onSuccess() {
    this.failures = 0;
    this.state = 'CLOSED';
  }
  
  onFailure() {
    this.failures++;
    if (this.failures >= this.failureThreshold) {
      this.state = 'OPEN';
      this.nextAttempt = Date.now() + this.resetTimeout;
    }
  }
}

module.exports = {
  GrpcError,
  ErrorCodes,
  createErrorInterceptor,
  serverErrorInterceptor,
  expressErrorHandler,
  transformToGrpcError,
  transformGrpcError,
  withRetry,
  CircuitBreaker
};
