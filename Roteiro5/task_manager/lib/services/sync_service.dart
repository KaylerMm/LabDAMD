import 'dart:async';
import '../models/task.dart';
import 'database_service.dart';
import 'api_service.dart';
import 'connectivity_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ConnectivityService _connectivity = ConnectivityService();
  Timer? _syncTimer;
  bool _isSyncing = false;

  void initialize() {
    // Escutar mudanças de conectividade
    _connectivity.connectionStream.listen((isOnline) {
      if (isOnline) {
        _performSync();
      }
    });

    // Sincronizar periodicamente quando online
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_connectivity.isOnline && !_isSyncing) {
        _performSync();
      }
    });
  }

  Future<void> syncNow() async {
    if (!_connectivity.isOnline) {
      print('📱 Offline - sync adiado');
      return;
    }
    
    await _performSync();
  }

  Future<void> _performSync() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    print('🔄 Iniciando sincronização...');

    try {
      // 1. Enviar tasks locais que precisam ser sincronizadas
      await _syncLocalTasks();
      
      // 2. Buscar atualizações do servidor
      await _syncFromServer();
      
      print('✅ Sincronização concluída');
    } catch (e) {
      print('❌ Erro na sincronização: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncLocalTasks() async {
    final localTasks = await DatabaseService.getTasksNeedingSync();
    
    if (localTasks.isEmpty) {
      print('📝 Nenhuma task local para sincronizar');
      return;
    }

    print('📤 Sincronizando ${localTasks.length} tasks locais...');

    for (var task in localTasks) {
      try {
        if (task.serverId == null) {
          // Task nova, criar no servidor
          final serverTask = await ApiService.createTask(task);
          await DatabaseService.markTaskAsSynced(task.id!, serverTask.serverId!);
          print('✅ Task criada no servidor: ${task.title} -> ${serverTask.serverId}');
        } else {
          // Task existente, atualizar no servidor
          await ApiService.updateTask(task);
          await DatabaseService.markTaskAsSynced(task.id!, task.serverId!);
          print('✅ Task atualizada no servidor: ${task.title}');
        }
      } catch (e) {
        print('⚠️ Falha ao sincronizar task "${task.title}": $e');
      }
    }
  }

  Future<void> _syncFromServer() async {
    try {
      print('📥 Buscando atualizações do servidor...');
      
      final serverTasks = await ApiService.getAllTasks();
      
      if (serverTasks.isNotEmpty) {
        await DatabaseService.updateFromServer(serverTasks);
        print('✅ ${serverTasks.length} tasks sincronizadas do servidor');
      } else {
        print('📭 Nenhuma task no servidor');
      }
    } catch (e) {
      print('⚠️ Falha ao buscar tasks do servidor: $e');
    }
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}