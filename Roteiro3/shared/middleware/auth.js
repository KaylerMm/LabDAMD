const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// gRPC Authentication Interceptor
function createAuthInterceptor() {
  return (options, nextCall) => {
    return new Proxy(nextCall(options), {
      get(target, property, receiver) {
        if (property === 'start') {
          return function(metadata, listener, next) {
            // Extract token from metadata
            const authHeader = metadata.get('authorization')[0];
            
            if (!authHeader) {
              const error = new Error('No authorization token provided');
              error.code = 16; // UNAUTHENTICATED
              listener(error);
              return;
            }

            const token = authHeader.replace('Bearer ', '');
            
            try {
              const decoded = jwt.verify(token, JWT_SECRET);
              // Add user info to metadata for downstream services
              metadata.add('user-id', decoded.userId);
              metadata.add('user-role', decoded.role);
              
              target.start(metadata, listener, next);
            } catch (err) {
              const error = new Error('Invalid or expired token');
              error.code = 16; // UNAUTHENTICATED
              listener(error);
            }
          };
        }
        return Reflect.get(target, property, receiver);
      }
    });
  };
}

// Server-side authentication interceptor
function serverAuthInterceptor(call, callback, next) {
  const metadata = call.metadata;
  const authHeader = metadata.get('authorization')[0];
  
  // Skip auth for public methods
  const publicMethods = ['/UserService/Login', '/UserService/Register'];
  if (publicMethods.includes(call.getPath())) {
    return next();
  }
  
  if (!authHeader) {
    const error = new Error('Authentication required');
    error.code = 16; // UNAUTHENTICATED
    return callback(error);
  }

  const token = authHeader.replace('Bearer ', '');
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    call.user = decoded; // Attach user info to call context
    next();
  } catch (err) {
    const error = new Error('Invalid or expired token');
    error.code = 16; // UNAUTHENTICATED
    callback(error);
  }
}

// Express middleware for JWT validation
function expressAuthMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader) {
    return res.status(401).json({ error: 'No authorization token provided' });
  }

  const token = authHeader.replace('Bearer ', '');
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

// Token generation utility
function generateToken(payload, expiresIn = '24h') {
  return jwt.sign(payload, JWT_SECRET, { expiresIn });
}

// Token validation utility
function validateToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (err) {
    throw new Error('Invalid token');
  }
}

module.exports = {
  createAuthInterceptor,
  serverAuthInterceptor,
  expressAuthMiddleware,
  generateToken,
  validateToken,
  JWT_SECRET
};
