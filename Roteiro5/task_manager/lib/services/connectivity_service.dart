import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  bool _isOnline = false;
  Timer? _checkTimer;

  bool get isOnline => _isOnline;
  Stream<bool> get connectionStream => _connectionController.stream;

  Future<void> initialize() async {
    // Verificar conectividade inicial
    await _checkConnectivity();
    
    // Escutar mudanças de conectividade
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _onConnectivityChanged([result]);
    });
    
    // Verificar periodicamente a conectividade real com o servidor
    _startPeriodicCheck();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    await _onConnectivityChanged([connectivityResult]);
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> result) async {
    final hasConnection = result.any((result) => 
      result != ConnectivityResult.none
    );

    if (hasConnection) {
      // Tem conexão de rede, mas vamos verificar se o servidor está acessível
      final serverReachable = await ApiService.isServerReachable();
      _updateConnectionStatus(serverReachable);
    } else {
      _updateConnectionStatus(false);
    }
  }

  void _updateConnectionStatus(bool isConnected) {
    if (_isOnline != isConnected) {
      _isOnline = isConnected;
      _connectionController.add(_isOnline);
      
      print(_isOnline 
        ? '🌐 Conectado - servidor acessível' 
        : '📱 Offline - sem conexão ou servidor indisponível'
      );
    }
  }

  void _startPeriodicCheck() {
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkConnectivity();
    });
  }

  void dispose() {
    _checkTimer?.cancel();
    _connectionController.close();
  }
}