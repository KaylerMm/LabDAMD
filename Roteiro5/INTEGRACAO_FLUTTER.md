# 📦 DEPENDÊNCIAS FLUTTER NECESSÁRIAS

## pubspec.yaml

Adicione estas dependências ao seu `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existentes
  sqflite: ^2.3.0
  path: ^1.8.3
  http: ^1.2.0
  
  # NOVAS - Para upload de imagens
  image_picker: ^1.0.7        # Captura de fotos
  path_provider: ^2.1.2       # Acesso ao sistema de arquivos
```

## Instalação

```bash
cd /home/kayler/Puc/Lab\ App\ Mov/Roteiro5/task_manager
flutter pub get
```

## Permissões Android

### android/app/src/main/AndroidManifest.xml

Adicione dentro de `<manifest>`:

```xml
<!-- Permissões de câmera e armazenamento -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

<!-- Para Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

E adicione dentro de `<application>`:

```xml
<!-- Provider para compartilhar arquivos -->
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
```

### android/app/src/main/res/xml/file_paths.xml

Crie este arquivo se não existir:

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external_files" path="." />
    <cache-path name="cache" path="." />
</paths>
```

## Estrutura de Arquivos Flutter

```
lib/
├── services/
│   ├── api_service.dart          # Existente
│   └── image_upload_service.dart # NOVO - Use o arquivo FLUTTER_UPLOAD_SERVICE.dart
├── screens/
│   ├── home_screen.dart          # Existente
│   └── camera_screen.dart        # NOVO - Use o arquivo FLUTTER_CAMERA_SCREEN.dart
└── models/
    └── task.dart                 # Existente
```

## Como Integrar

### 1. Copiar serviço de upload

```bash
cp FLUTTER_UPLOAD_SERVICE.dart task_manager/lib/services/image_upload_service.dart
```

### 2. Copiar tela de câmera

```bash
cp FLUTTER_CAMERA_SCREEN.dart task_manager/lib/screens/camera_screen.dart
```

### 3. Adicionar botão na lista de tasks

Em `home_screen.dart`, adicione um botão para abrir a câmera:

```dart
// No ListTile de cada task, adicione:
trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    // Botão existente de delete
    IconButton(
      icon: Icon(Icons.delete),
      onPressed: () => _deleteTask(task.id),
    ),
    // NOVO - Botão de câmera
    IconButton(
      icon: Icon(Icons.camera_alt),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraScreen(taskId: task.id),
          ),
        );
      },
    ),
  ],
),
```

### 4. Adicionar import

No topo de `home_screen.dart`:

```dart
import '../screens/camera_screen.dart';
```

## Teste Rápido

1. Instalar dependências:
```bash
cd task_manager
flutter pub get
```

2. Compilar e instalar:
```bash
flutter run
```

3. No app:
   - Abrir uma task
   - Clicar no ícone de câmera 📷
   - Tirar foto
   - Confirmar upload

## Troubleshooting

### Erro de permissão de câmera
- Verifique se as permissões estão no AndroidManifest.xml
- Desinstale e reinstale o app
- Nas configurações do Android, dê permissão manual

### Erro de conexão
```bash
adb reverse tcp:3000 tcp:3000
adb reverse tcp:4566 tcp:4566
```

### Erro ao buscar imagens
- Verifique se o servidor está rodando: `curl http://localhost:3000/api/health`
- Verifique se o LocalStack está rodando: `docker ps`

## URLs Corretas

No Flutter, use:
- **API Upload**: `http://localhost:3000/api/upload/base64`
- **API List**: `http://localhost:3000/api/images`
- **S3 Images**: `http://localhost:4566/shopping-images/[IMAGE_ID].jpg`

## Build para Release

```bash
flutter build apk --release
```

O APK estará em: `build/app/outputs/flutter-apk/app-release.apk`

---

**Pronto para integrar! 🚀**
