import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TodoPriority {
  low('low', 'Low', Color(0xFF4CAF50)),
  medium('medium', 'Medium', Color(0xFFFF9800)),
  high('high', 'High', Color(0xFFF44336));

  const TodoPriority(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  static TodoPriority fromString(String value) {
    return TodoPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => TodoPriority.medium,
    );
  }
}

enum TodoCategory {
  personal('personal', 'Personal', Icons.person, Color(0xFF2196F3)),
  work('work', 'Work', Icons.work, Color(0xFF9C27B0)),
  shopping('shopping', 'Shopping', Icons.shopping_cart, Color(0xFF4CAF50)),
  health('health', 'Health', Icons.health_and_safety, Color(0xFFE91E63)),
  education('education', 'Education', Icons.school, Color(0xFF3F51B5)),
  finance(
      'finance', 'Finance', Icons.account_balance_wallet, Color(0xFF795548)),
  travel('travel', 'Travel', Icons.flight, Color(0xFF00BCD4)),
  other('other', 'Other', Icons.category, Color(0xFF607D8B));

  const TodoCategory(this.value, this.label, this.icon, this.color);
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  static TodoCategory fromString(String value) {
    return TodoCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => TodoCategory.other,
    );
  }
}

class Todo {
  String id;
  String title;
  String content;
  String ownerId;
  bool isCompleted;
  String createdAt;
  String updatedAt;
  String dueDate;
  String? dueTime; // Optional time for due date
  TodoPriority priority;
  TodoCategory category;
  List<String> tags; // For additional categorization
  bool isImportant; // Star/favorite feature

  Todo({
    required this.id,
    required this.title,
    required this.content,
    required this.ownerId,
    this.isCompleted = false,
    String? createdAt,
    String? updatedAt,
    String? dueDate,
    this.dueTime,
    this.priority = TodoPriority.medium,
    this.category = TodoCategory.other,
    this.tags = const [],
    this.isImportant = false,
  })  : this.createdAt = createdAt ?? DateTime.now().toIso8601String(),
        this.updatedAt = updatedAt ?? DateTime.now().toIso8601String(),
        this.dueDate = dueDate ?? DateTime.now().toIso8601String();

  factory Todo.fromMap(Map<String, dynamic> data, String documentId) {
    return Todo(
      id: documentId,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      ownerId: data['owner_id'] ?? '',
      isCompleted: data['is_completed'] ?? false,
      createdAt: data['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: data['updated_at'] ?? DateTime.now().toIso8601String(),
      dueDate: data['due_date'] ??
          data['created_at'] ??
          DateTime.now().toIso8601String(),
      dueTime: data['due_time'],
      priority: TodoPriority.fromString(data['priority'] ?? 'medium'),
      category: TodoCategory.fromString(data['category'] ?? 'other'),
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      isImportant: data['is_important'] ?? false,
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
      'due_date': dueDate,
      'due_time': dueTime,
      'priority': priority.value,
      'category': category.value,
      'tags': tags,
      'is_important': isImportant,
    };
  }

  Todo copyWith({
    String? id,
    String? title,
    String? content,
    String? ownerId,
    bool? isCompleted,
    String? createdAt,
    String? updatedAt,
    String? dueDate,
    String? dueTime,
    TodoPriority? priority,
    TodoCategory? category,
    List<String>? tags,
    bool? isImportant,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      ownerId: ownerId ?? this.ownerId,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isImportant: isImportant ?? this.isImportant,
    );
  }

  // Helper methods
  bool get isOverdue {
    if (isCompleted) return false;
    try {
      final dueDateTime = DateTime.parse(dueDate);
      final now = DateTime.now();

      if (dueTime != null) {
        // Parse time and combine with due date
        final timeParts = dueTime!.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final dueDateTimeWithTime = DateTime(
          dueDateTime.year,
          dueDateTime.month,
          dueDateTime.day,
          hour,
          minute,
        );
        return now.isAfter(dueDateTimeWithTime);
      } else {
        // Just compare dates
        final today = DateTime(now.year, now.month, now.day);
        final due =
            DateTime(dueDateTime.year, dueDateTime.month, dueDateTime.day);
        return today.isAfter(due);
      }
    } catch (e) {
      return false;
    }
  }

  bool get isDueToday {
    try {
      final dueDateTime = DateTime.parse(dueDate);
      final now = DateTime.now();
      return dueDateTime.year == now.year &&
          dueDateTime.month == now.month &&
          dueDateTime.day == now.day;
    } catch (e) {
      return false;
    }
  }

  String get dueDateFormatted {
    try {
      final dueDateTime = DateTime.parse(dueDate);
      final now = DateTime.now();
      final difference = dueDateTime.difference(now).inDays;

      if (difference == 0) return 'Today';
      if (difference == 1) return 'Tomorrow';
      if (difference == -1) return 'Yesterday';
      if (difference > 1 && difference <= 7) return '${difference} days';
      if (difference < -1 && difference >= -7)
        return '${difference.abs()} days ago';

      return DateFormat('MMM d, yyyy').format(dueDateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
