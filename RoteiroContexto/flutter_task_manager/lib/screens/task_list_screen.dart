import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/sensor_service.dart';
import '../services/location_service.dart';
import '../services/camera_service.dart';
import '../screens/task_form_screen.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  String _filter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _setupShakeDetection();
  }

  @override
  void dispose() {
    SensorService.instance.stop();
    super.dispose();
  }

  void _setupShakeDetection() {
    SensorService.instance.startShakeDetection(() {
      _showShakeDialog();
    });
  }

  void _showShakeDialog() {
    final pendingTasks = _tasks.where((t) => !t.completed).toList();
    
    if (pendingTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 No pending tasks!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vibration, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(child: Text('Shake detected!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a task to complete:'),
            const SizedBox(height: 16),
            ...pendingTasks.take(3).map((task) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _completeTaskByShake(task),
              ),
            )),
            if (pendingTasks.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${pendingTasks.length - 3} others',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTaskByShake(Task task) async {
    try {
      final updated = task.copyWith(
        completed: true,
        completedAt: DateTime.now(),
        completedBy: 'shake',
      );

      await DatabaseService.instance.update(updated);
      Navigator.pop(context);
      await _loadTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "${task.title}" completed via shake!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    try {
      final tasks = await DatabaseService.instance.readAll();
      
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Load error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Task> get _filteredTasks {
    switch (_filter) {
      case 'pending':
        return _tasks.where((t) => !t.completed).toList();
      case 'completed':
        return _tasks.where((t) => t.completed).toList();
      case 'nearby':
        return _tasks;
      default:
        return _tasks;
    }
  }

  Map<String, int> get _statistics {
    final total = _tasks.length;
    final completed = _tasks.where((t) => t.completed).length;
    final pending = total - completed;
    final completionRate = total > 0 ? ((completed / total) * 100).round() : 0;
    
    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'completionRate': completionRate,
    };
  }

  Future<void> _filterByNearby() async {
    final position = await LocationService.instance.getCurrentLocation();
    
    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Could not get location'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final nearbyTasks = await DatabaseService.instance.getTasksNearLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusInMeters: 1000,
    );

    setState(() {
      _tasks = nearbyTasks;
      _filter = 'nearby';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 ${nearbyTasks.length} nearby task(s)'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm deletion'),
        content: Text('Delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (task.hasPhoto) {
          await CameraService.instance.deletePhoto(task.photoPath!);
        }
        
        await DatabaseService.instance.delete(task.id!);
        await _loadTasks();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🗑️ Task deleted'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleComplete(Task task) async {
    try {
      final updated = task.copyWith(
        completed: !task.completed,
        completedAt: !task.completed ? DateTime.now() : null,
        completedBy: !task.completed ? 'manual' : null,
      );

      await DatabaseService.instance.update(updated);
      await _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _statistics;
    final filteredTasks = _filteredTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              if (value == 'nearby') {
                _filterByNearby();
              } else {
                setState(() {
                  _filter = value;
                  if (value != 'nearby') _loadTasks();
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list_alt),
                    SizedBox(width: 8),
                    Text('All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    Icon(Icons.pending_outlined),
                    SizedBox(width: 8),
                    Text('Pending'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline),
                    SizedBox(width: 8),
                    Text('Completed'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'nearby',
                child: Row(
                  children: [
                    Icon(Icons.near_me),
                    SizedBox(width: 8),
                    Text('Nearby'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AlertDialog(
                  title: Text('💡 Tips'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Tap card to edit'),
                      SizedBox(height: 8),
                      Text('• Check to complete'),
                      SizedBox(height: 8),
                      Text('• Shake phone for quick completion!'),
                      SizedBox(height: 8),
                      Text('• Use filters to organize'),
                      SizedBox(height: 8),
                      Text('• Add photos and location'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade700],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Total',
                          value: stats['total'].toString(),
                          icon: Icons.list_alt,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _StatItem(
                          label: 'Done',
                          value: stats['completed'].toString(),
                          icon: Icons.check_circle,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _StatItem(
                          label: 'Rate',
                          value: '${stats['completionRate']}%',
                          icon: Icons.trending_up,
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: filteredTasks.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredTasks.length,
                            itemBuilder: (context, index) {
                              final task = filteredTasks[index];
                              return TaskCard(
                                task: task,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TaskFormScreen(task: task),
                                    ),
                                  );
                                  if (result == true) _loadTasks();
                                },
                                onDelete: () => _deleteTask(task),
                                onCheckboxChanged: (value) => _toggleComplete(task),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TaskFormScreen(),
            ),
          );
          if (result == true) _loadTasks();
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_filter) {
      case 'pending':
        message = '🎉 No pending tasks!';
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        message = '📋 No completed tasks yet';
        icon = Icons.pending_outlined;
        break;
      case 'nearby':
        message = '📍 No nearby tasks';
        icon = Icons.near_me;
        break;
      default:
        message = '📝 No tasks yet.\nTap + to create!';
        icon = Icons.add_task;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}