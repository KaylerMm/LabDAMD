import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  TaskProvider(this._apiService);

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTasks(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _apiService.listTasks(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTaskWithImage({
    required String userId,
    required String title,
    required String description,
    required String imageBase64,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final task = await _apiService.createTaskWithImage(
        userId: userId,
        title: title,
        description: description,
        imageBase64: imageBase64,
      );
      _tasks.insert(0, task);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    bool? completed,
  }) async {
    try {
      final updatedTask = await _apiService.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        completed: completed,
      );

      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _apiService.deleteTask(taskId);
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
