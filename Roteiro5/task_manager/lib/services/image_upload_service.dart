// lib/services/image_upload_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageUploadService {
  static const String baseUrl = 'http://localhost:3000/api';
  final ImagePicker _picker = ImagePicker();

  // Upload de imagem capturada da câmera
  Future<Map<String, dynamic>?> uploadFromCamera(String taskId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _uploadImage(image, taskId);
    } catch (e) {
      print('Erro ao capturar imagem: $e');
      return null;
    }
  }

  // Upload de imagem da galeria
  Future<Map<String, dynamic>?> uploadFromGallery(String taskId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _uploadImage(image, taskId);
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
      return null;
    }
  }

  // Método privado para fazer o upload
  Future<Map<String, dynamic>?> _uploadImage(
    XFile image,
    String taskId,
  ) async {
    try {
      // Ler arquivo como bytes
      final bytes = await File(image.path).readAsBytes();

      // Converter para base64
      final base64Image = base64Encode(bytes);

      // Preparar payload
      final payload = {
        'image': 'data:image/jpeg;base64,$base64Image',
        'taskId': taskId,
        'description': 'Foto da tarefa ${DateTime.now()}',
      };

      // Fazer requisição
      final response = await http.post(
        Uri.parse('$baseUrl/upload/base64'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Upload sucesso! Image ID: ${data['imageId']}');
        return data;
      } else {
        print('❌ Erro no upload: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao fazer upload: $e');
      return null;
    }
  }

  // Listar imagens de uma task
  Future<List<dynamic>> getImagesForTask(String taskId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/images/$taskId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['images'] ?? [];
      }
      return [];
    } catch (e) {
      print('Erro ao buscar imagens: $e');
      return [];
    }
  }

  // Listar todas as imagens
  Future<List<dynamic>> getAllImages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/images'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['images'] ?? [];
      }
      return [];
    } catch (e) {
      print('Erro ao buscar imagens: $e');
      return [];
    }
  }

  // Deletar imagem
  Future<bool> deleteImage(String imageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/images/$imageId'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao deletar imagem: $e');
      return false;
    }
  }
}
