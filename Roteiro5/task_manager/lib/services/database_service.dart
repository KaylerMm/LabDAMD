import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseService {
  static Database? _database;
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'task_manager_v2.db');
    
    print('📱 Inicializando database em: $path');
    
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion == 1 && newVersion == 2) {
          await db.execute('ALTER TABLE tasks ADD COLUMN priority TEXT NOT NULL DEFAULT "medium"');
        }
      },
    );
  }

  static Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        priority TEXT NOT NULL DEFAULT 'medium',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        needsSync INTEGER NOT NULL DEFAULT 1,
        serverId TEXT
      )
    ''');
    
    print('✅ Tabela tasks criada com sucesso');
  }

  // CRUD Operations
  static Future<String> insertTask(Task task) async {
    final db = await database;
    final id = task.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    final taskWithId = task.copyWith(
      id: id,
      needsSync: true,
      updatedAt: DateTime.now(),
    );
    
    await db.insert('tasks', taskWithId.toMap());
    print('✅ Task inserida: ${taskWithId.title} (ID: $id)');
    
    return id;
  }

  static Future<List<Task>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'createdAt DESC',
    );
    
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  static Future<Task?> getTask(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  static Future<void> updateTask(Task task) async {
    final db = await database;
    
    final updatedTask = task.copyWith(
      needsSync: true,
      updatedAt: DateTime.now(),
    );
    
    await db.update(
      'tasks',
      updatedTask.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    
    print('✅ Task atualizada: ${task.title}');
  }

  static Future<void> deleteTask(String id) async {
    final db = await database;
    
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    print('✅ Task removida: $id');
  }

  // Sync Operations
  static Future<List<Task>> getTasksNeedingSync() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'needsSync = ?',
      whereArgs: [1],
    );
    
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  static Future<void> markTaskAsSynced(String localId, String serverId) async {
    final db = await database;
    
    await db.update(
      'tasks',
      {
        'needsSync': 0,
        'serverId': serverId,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
    
    print('✅ Task marcada como sincronizada: $localId -> $serverId');
  }

  static Future<void> updateFromServer(List<Task> serverTasks) async {
    final db = await database;
    
    // Primeiro, buscar todas as tasks locais
    final localTasks = await getAllTasks();
    final localTasksMap = {for (var task in localTasks) task.serverId: task};
    
    for (var serverTask in serverTasks) {
      final serverId = serverTask.serverId;
      if (serverId == null) continue;
      
      if (localTasksMap.containsKey(serverId)) {
        // Task existe localmente, atualizar se necessário
        final localTask = localTasksMap[serverId]!;
        
        // Só atualizar se a task local não precisa ser sincronizada
        if (!localTask.needsSync) {
          final updatedTask = serverTask.copyWith(
            id: localTask.id,
            needsSync: false,
          );
          
          await db.update(
            'tasks',
            updatedTask.toMap(),
            where: 'id = ?',
            whereArgs: [localTask.id],
          );
        }
      } else {
        // Task nova do servidor, inserir
        final newId = DateTime.now().millisecondsSinceEpoch.toString();
        final newTask = serverTask.copyWith(
          id: newId,
          needsSync: false,
        );
        
        await db.insert('tasks', newTask.toMap());
        print('📥 Nova task do servidor: ${newTask.title}');
      }
    }
  }

  static Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('tasks');
    print('🗑️ Database limpo');
  }
}