import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/task_service.dart';
import '../models/task.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Inicializar o TaskService quando a tela for criada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskService>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskService>(
      builder: (context, taskService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Task Manager Offline',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            actions: [
              // Indicador de conectividade
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    Icon(
                      taskService.isOnline 
                        ? Icons.cloud_done 
                        : Icons.cloud_off,
                      color: taskService.isOnline 
                        ? Colors.green.shade300 
                        : Colors.orange.shade300,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      taskService.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: taskService.isOnline 
                          ? Colors.green.shade300 
                          : Colors.orange.shade300,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Botão de sync
              IconButton(
                onPressed: taskService.isOnline && !taskService.isLoading
                  ? () => taskService.syncTasks()
                  : null,
                icon: taskService.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync),
                tooltip: 'Sincronizar',
              ),
            ],
          ),
          body: Column(
            children: [
              // Status bar com estatísticas
              Container(
                width: double.infinity,
                color: Colors.grey.shade100,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total',
                        taskService.totalTasks,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        'Pendentes',
                        taskService.pendingCount,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        'Completas',
                        taskService.completedCount,
                        Colors.green,
                      ),
                    ),
                    if (taskService.unsyncedCount > 0)
                      Expanded(
                        child: _buildStatCard(
                          'Não Sync',
                          taskService.unsyncedCount,
                          Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Lista de tasks
              Expanded(
                child: taskService.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : taskService.tasks.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhuma tarefa ainda',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Toque no + para adicionar sua primeira tarefa',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: taskService.tasks.length,
                        itemBuilder: (context, index) {
                          final task = taskService.tasks[index];
                          return _buildTaskItem(task, taskService);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddTaskScreen(),
                ),
              );
            },
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(Task task, TaskService taskService) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkbox
            Checkbox(
              value: task.completed,
              onChanged: (value) {
                taskService.toggleTaskCompletion(task);
              },
              activeColor: Colors.green,
            ),
            // Indicador de sync
            if (task.needsSync)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              )
            else
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.completed 
              ? TextDecoration.lineThrough 
              : TextDecoration.none,
            color: task.completed 
              ? Colors.grey 
              : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: task.description.isNotEmpty
          ? Text(
              task.description,
              style: TextStyle(
                decoration: task.completed 
                  ? TextDecoration.lineThrough 
                  : TextDecoration.none,
                color: task.completed 
                  ? Colors.grey 
                  : Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                _showEditDialog(task, taskService);
                break;
              case 'delete':
                _showDeleteDialog(task, taskService);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Task task, TaskService taskService) {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Tarefa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                taskService.updateTask(
                  task,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Task task, TaskService taskService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Tarefa'),
        content: Text('Tem certeza que deseja excluir "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              taskService.deleteTask(task);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}