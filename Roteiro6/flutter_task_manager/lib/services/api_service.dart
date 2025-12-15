import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<Map<String, dynamic>> uploadImage({
    required String userId,
    required String taskId,
    required String imageBase64,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/upload'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'taskId': taskId,
          'imageData': imageBase64,
          'contentType': contentType,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upload image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  Future<Task> createTask({
    required String userId,
    required String title,
    required String description,
    String imageKey = '',
    String imageUrl = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'title': title,
          'description': description,
          'imageKey': imageKey,
          'imageUrl': imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return Task.fromJson(data['task']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to create task: ${response.body}');
      }
    } catch (e) {
      throw Exception('Create task error: $e');
    }
  }

  Future<Task> createTaskWithImage({
    required String userId,
    required String title,
    required String description,
    required String imageBase64,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/tasks-with-image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'title': title,
          'description': description,
          'imageData': imageBase64,
          'contentType': contentType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return Task.fromJson(data['task']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to create task with image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Create task with image error: $e');
    }
  }

  Future<List<Task>> listTasks(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tasks?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return (data['tasks'] as List)
              .map((task) => Task.fromJson(task))
              .toList();
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to list tasks: ${response.body}');
      }
    } catch (e) {
      throw Exception('List tasks error: $e');
    }
  }

  Future<Task> getTask(String taskId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tasks/$taskId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return Task.fromJson(data['task']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to get task: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get task error: $e');
    }
  }

  Future<Task> updateTask({
    required String taskId,
    String? title,
    String? description,
    bool? completed,
    String? imageKey,
    String? imageUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (completed != null) body['completed'] = completed;
      if (imageKey != null) body['imageKey'] = imageKey;
      if (imageUrl != null) body['imageUrl'] = imageUrl;

      final response = await http.put(
        Uri.parse('$baseUrl/api/tasks/$taskId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return Task.fromJson(data['task']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to update task: ${response.body}');
      }
    } catch (e) {
      throw Exception('Update task error: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/tasks/$taskId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!data['success']) {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to delete task: ${response.body}');
      }
    } catch (e) {
      throw Exception('Delete task error: $e');
    }
  }
}
