class Task {
  String id;
  String title;
  String content;
  String ownerId;
  bool isCompleted;
  String createdAt;
  String updatedAt;
  String taskDate;

  Task({
    required this.id,
    required this.title,
    required this.content,
    required this.ownerId,
    this.isCompleted = false,
    String? createdAt,
    String? updatedAt,
    String? taskDate,
  })  : this.createdAt = createdAt ?? DateTime.now().toIso8601String(),
        this.updatedAt = updatedAt ?? DateTime.now().toIso8601String(),
        this.taskDate = taskDate ?? DateTime.now().toIso8601String();

  factory Task.fromMap(Map<String, dynamic> data, String documentId) {
    return Task(
      id: documentId,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      ownerId: data['owner_id'] ?? '',
      isCompleted: data['is_completed'] ?? false,
      createdAt: data['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: data['updated_at'] ?? DateTime.now().toIso8601String(),
      taskDate: data['task_date'] ??
          data['created_at'] ??
          DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'owner_id': ownerId,
      'is_completed': isCompleted,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'task_date': taskDate,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? content,
    String? ownerId,
    bool? isCompleted,
    String? createdAt,
    String? updatedAt,
    String? taskDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      ownerId: ownerId ?? this.ownerId,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      taskDate: taskDate ?? this.taskDate,
    );
  }
}
