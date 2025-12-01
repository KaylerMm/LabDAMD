import 'package:flutter/foundation.dart';
import '../models/task.dart';
import 'database_service.dart';
import 'sync_service.dart';
import 'connectivity_service.dart';

class TaskService extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  
  final SyncService _syncService = SyncService();
  final ConnectivityService _connectivity = ConnectivityService();

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get isOnline => _connectivity.isOnline;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Inicializar serviços
      await _connectivity.initialize();
      _syncService.initialize();

      // Escutar mudanças de conectividade
      _connectivity.connectionStream.listen((isOnline) {
        notifyListeners(); // Atualizar UI quando conectividade mudar
      });

      // Carregar tasks do banco local
      await loadTasks();
      
      // Tentar sincronizar se estiver online
      if (_connectivity.isOnline) {
        await _syncService.syncNow();
        await loadTasks(); // Recarregar após sync
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTasks() async {
    try {
      _tasks = await DatabaseService.getAllTasks();
      notifyListeners();
      print('📋 ${_tasks.length} tasks carregadas');
    } catch (e) {
      print('❌ Erro ao carregar tasks: $e');
    }
  }

  Future<void> addTask(String title, String description) async {
    if (title.trim().isEmpty) return;

    try {
      final task = Task(
        title: title.trim(),
        description: description.trim(),
        needsSync: true,
      );

      final id = await DatabaseService.insertTask(task);
      print('✅ Task adicionada: $title (ID: $id)');
      
      await loadTasks();

      // Tentar sincronizar imediatamente se estiver online
      if (_connectivity.isOnline) {
        _syncService.syncNow();
      }
    } catch (e) {
      print('❌ Erro ao adicionar task: $e');
    }
  }

  Future<void> updateTask(Task task, {
    String? title,
    String? description,
    bool? completed,
  }) async {
    try {
      final updatedTask = task.copyWith(
        title: title ?? task.title,
        description: description ?? task.description,
        completed: completed ?? task.completed,
        needsSync: true,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.updateTask(updatedTask);
      print('✅ Task atualizada: ${updatedTask.title}');
      
      await loadTasks();

      // Tentar sincronizar imediatamente se estiver online
      if (_connectivity.isOnline) {
        _syncService.syncNow();
      }
    } catch (e) {
      print('❌ Erro ao atualizar task: $e');
    }
  }

  Future<void> toggleTaskCompletion(Task task) async {
    await updateTask(task, completed: !task.completed);
  }

  Future<void> deleteTask(Task task) async {
    try {
      await DatabaseService.deleteTask(task.id!);
      print('✅ Task removida: ${task.title}');
      
      await loadTasks();

      // Se a task tinha serverId, precisamos deletar do servidor também
      if (task.serverId != null && _connectivity.isOnline) {
        try {
          // TODO: Implementar delete no servidor
          print('📤 Task deletada do servidor: ${task.serverId}');
        } catch (e) {
          print('⚠️ Erro ao deletar do servidor: $e');
        }
      }
    } catch (e) {
      print('❌ Erro ao remover task: $e');
    }
  }

  Future<void> syncTasks() async {
    if (!_connectivity.isOnline) {
      print('📱 Offline - não é possível sincronizar agora');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _syncService.syncNow();
      await loadTasks();
      print('🔄 Sincronização manual concluída');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Métodos utilitários
  List<Task> get pendingTasks => _tasks.where((task) => !task.completed).toList();
  List<Task> get completedTasks => _tasks.where((task) => task.completed).toList();
  List<Task> get unsyncedTasks => _tasks.where((task) => task.needsSync).toList();
  
  int get totalTasks => _tasks.length;
  int get completedCount => completedTasks.length;
  int get pendingCount => pendingTasks.length;
  int get unsyncedCount => unsyncedTasks.length;

  @override
  void dispose() {
    _syncService.dispose();
    _connectivity.dispose();
    super.dispose();
  }
}