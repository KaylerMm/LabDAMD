class Task {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String imageKey;
  final String imageUrl;
  final bool completed;
  final int createdAt;
  final int updatedAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.imageKey,
    required this.imageUrl,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageKey: json['image_key'] ?? '',
      imageUrl: json['image_url'] ?? '',
      completed: json['completed'] ?? false,
      createdAt: json['created_at'] ?? 0,
      updatedAt: json['updated_at'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'image_key': imageKey,
      'image_url': imageUrl,
      'completed': completed,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
