import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.100.230:3000/api';
  
  // Testar conectividade com o servidor
  static Future<bool> isServerReachable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/../health'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('🌐 Servidor não acessível: $e');
      return false;
    }
  }

  // Buscar todas as tasks do servidor
  static Future<List<Task>> getAllTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> tasksJson = data['data'];
          return tasksJson.map((json) => Task.fromJson(json)).toList();
        }
      }
      
      throw Exception('Falha ao buscar tasks: ${response.statusCode}');
    } catch (e) {
      print('❌ Erro ao buscar tasks: $e');
      rethrow;
    }
  }

  // Criar task no servidor
  static Future<Task> createTask(Task task) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          return Task.fromJson(data['data'], localId: task.id);
        }
      }
      
      throw Exception('Falha ao criar task: ${response.statusCode}');
    } catch (e) {
      print('❌ Erro ao criar task: $e');
      rethrow;
    }
  }

  // Atualizar task no servidor
  static Future<Task> updateTask(Task task) async {
    try {
      if (task.serverId == null) {
        throw Exception('Task não tem serverId para atualizar');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/tasks/${task.serverId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          return Task.fromJson(data['data'], localId: task.id);
        }
      }
      
      throw Exception('Falha ao atualizar task: ${response.statusCode}');
    } catch (e) {
      print('❌ Erro ao atualizar task: $e');
      rethrow;
    }
  }

  // Deletar task no servidor
  static Future<void> deleteTask(String serverId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$serverId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Falha ao deletar task: ${response.statusCode}');
      }
      
      print('✅ Task deletada no servidor: $serverId');
    } catch (e) {
      print('❌ Erro ao deletar task: $e');
      rethrow;
    }
  }
}