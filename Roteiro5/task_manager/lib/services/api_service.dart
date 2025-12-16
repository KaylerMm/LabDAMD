import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  // Lista de URLs para testar (ordem de prioridade)
  static const List<String> _baseUrls = [
    'http://localhost:3000/api',        // Android Emulator -> localhost (padrão)
    'http://localhost:3000/api',    // IP atual da rede
    'http://localhost:3000/api',      // Docker bridge
    'http://localhost:3000/api',       // localhost direto
  ];
  
  static String? _workingBaseUrl;
  
  static String get baseUrl {
    return _workingBaseUrl ?? _baseUrls.first;
  }
  
  // Testar conectividade com múltiplos URLs
  static Future<bool> isServerReachable() async {
    print('🔍 Testando conectividade com servidor...');
    
    // Se já temos uma URL que funciona, testar ela primeiro
    if (_workingBaseUrl != null) {
      if (await _testSingleUrl(_workingBaseUrl!)) {
        print('✅ Usando URL salva: $_workingBaseUrl');
        return true;
      } else {
        print('⚠️  URL salva não funciona mais, testando outras...');
        _workingBaseUrl = null;
      }
    }
    
    // Testar todas as URLs disponíveis
    for (String testBaseUrl in _baseUrls) {
      print('🌐 Testando: $testBaseUrl');
      
      if (await _testSingleUrl(testBaseUrl)) {
        _workingBaseUrl = testBaseUrl;
        print('✅ Conectado com sucesso: $testBaseUrl');
        return true;
      }
    }
    
    print('❌ Nenhuma URL funcionou - servidor offline ou inacessível');
    return false;
  }
  
  // Testar uma URL específica
  static Future<bool> _testSingleUrl(String testBaseUrl) async {
    try {
      final response = await http.get(
        Uri.parse('$testBaseUrl/../health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'healthy') {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('   ❌ Falhou: $e');
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