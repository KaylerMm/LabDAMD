class Task {
  final String? id;
  final String title;
  final String description;
  final bool completed;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool needsSync;
  final String? serverId;

  Task({
    this.id,
    required this.title,
    required this.description,
    this.completed = false,
    this.priority = 'medium',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.needsSync = true,
    this.serverId,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Converter para Map (para SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed ? 1 : 0,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'needsSync': needsSync ? 1 : 0,
      'serverId': serverId,
    };
  }

  // Criar Task do Map (do SQLite)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id']?.toString(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      completed: (map['completed'] as int) == 1,
      priority: map['priority'] ?? 'medium',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      needsSync: (map['needsSync'] as int) == 1,
      serverId: map['serverId']?.toString(),
    );
  }

  // Converter para JSON (para API)
  Map<String, dynamic> toJson() {
    final json = {
      'title': title,
      'description': description,
      'priority': priority,
    };
    
    // Só incluir campos opcionais se tiverem valor
    if (serverId != null) {
      json['id'] = serverId!;
    }
    
    return json;
  }

  // Criar Task do JSON (da API)
  factory Task.fromJson(Map<String, dynamic> json, {String? localId}) {
    return Task(
      id: localId,
      serverId: json['id']?.toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      completed: json['completed'] ?? false,
      priority: json['priority'] ?? 'medium',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      needsSync: false, // Vem do servidor, já sincronizado
    );
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        // Tentar formato "YYYY-MM-DD HH:MM:SS"
        try {
          final parts = dateTime.split(' ');
          if (parts.length == 2) {
            final dateParts = parts[0].split('-');
            final timeParts = parts[1].split(':');
            return DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
              int.parse(timeParts[2]),
            );
          }
        } catch (e2) {
          print('Erro ao fazer parse da data: $dateTime');
        }
      }
    }
    return DateTime.now();
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    String? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? needsSync,
    String? serverId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
      serverId: serverId ?? this.serverId,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, completed: $completed, needsSync: $needsSync, serverId: $serverId)';
  }
}