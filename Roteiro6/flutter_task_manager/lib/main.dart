import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'services/api_service.dart';
import 'screens/home_screen.dart';

void main() {
  final apiService = ApiService(baseUrl: 'http://10.0.2.2:3000');

  runApp(
    ChangeNotifierProvider(
      create: (_) => TaskProvider(apiService),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciador de Tarefas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
