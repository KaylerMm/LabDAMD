// lib/screens/camera_screen.dart
import 'package:flutter/material.dart';
import '../services/image_upload_service.dart';

class CameraScreen extends StatefulWidget {
  final String taskId;

  const CameraScreen({
    Key? key,
    required this.taskId,
  }) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImageUploadService _uploadService = ImageUploadService();
  bool _isUploading = false;
  List<dynamic> _images = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final images = await _uploadService.getImagesForTask(widget.taskId);
    setState(() {
      _images = images;
    });
  }

  Future<void> _captureAndUpload() async {
    setState(() {
      _isUploading = true;
    });

    final result = await _uploadService.uploadFromCamera(widget.taskId);

    setState(() {
      _isUploading = false;
    });

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Foto enviada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadImages(); // Recarregar lista
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erro ao enviar foto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _isUploading = true;
    });

    final result = await _uploadService.uploadFromGallery(widget.taskId);

    setState(() {
      _isUploading = false;
    });

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Foto enviada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadImages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erro ao enviar foto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteImage(String imageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('Deseja realmente deletar esta imagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _uploadService.deleteImage(imageId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagem deletada')),
        );
        _loadImages();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos da Tarefa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadImages,
          ),
        ],
      ),
      body: Column(
        children: [
          // Botões de ação
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _captureAndUpload,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Câmera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeria'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),

          // Lista de imagens
          Expanded(
            child: _images.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhuma foto ainda\nTire uma foto para começar!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      final image = _images[index];
                      return Card(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              image['s3Url'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.error),
                                );
                              },
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteImage(image['imageId']),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  image['uploadedAt'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
