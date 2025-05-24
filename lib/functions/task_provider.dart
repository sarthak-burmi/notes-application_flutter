import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todo_flutter_app/core/supaBase_client.dart';
import 'package:todo_flutter_app/functions/auth_provider.dart';
import 'package:todo_flutter_app/model/TaskModel.dart'; // Your Todo model

class TodoState {
  final List<Todo> todos;
  final bool isLoading;
  final String? error;
  final TodoFilter filter;
  final TodoSort sort;

  const TodoState({
    this.todos = const [],
    this.isLoading = false,
    this.error,
    this.filter = TodoFilter.all,
    this.sort = TodoSort.dueDate,
  });

  TodoState copyWith({
    List<Todo>? todos,
    bool? isLoading,
    String? error,
    TodoFilter? filter,
    TodoSort? sort,
  }) {
    return TodoState(
      todos: todos ?? this.todos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }

  // Get filtered and sorted todos
  List<Todo> get filteredTodos {
    List<Todo> filtered = [...todos];

    // Apply filter
    switch (filter) {
      case TodoFilter.all:
        break;
      case TodoFilter.pending:
        filtered = filtered.where((todo) => !todo.isCompleted).toList();
        break;
      case TodoFilter.completed:
        filtered = filtered.where((todo) => todo.isCompleted).toList();
        break;
      case TodoFilter.today:
        filtered = filtered.where((todo) => todo.isDueToday).toList();
        break;
      case TodoFilter.overdue:
        filtered = filtered.where((todo) => todo.isOverdue).toList();
        break;
      case TodoFilter.important:
        filtered = filtered
            .where((todo) => todo.isImportant && !todo.isCompleted)
            .toList();
        break;
    }

    // Apply sort
    switch (sort) {
      case TodoSort.dueDate:
        filtered.sort((a, b) {
          final aDate = DateTime.tryParse(a.dueDate) ?? DateTime.now();
          final bDate = DateTime.tryParse(b.dueDate) ?? DateTime.now();
          return aDate.compareTo(bDate);
        });
        break;
      case TodoSort.priority:
        filtered.sort((a, b) {
          final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
          return (priorityOrder[a.priority.value] ?? 1)
              .compareTo(priorityOrder[b.priority.value] ?? 1);
        });
        break;
      case TodoSort.created:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case TodoSort.alphabetical:
        filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return filtered;
  }

  // Get statistics
  TodoStats get stats {
    final total = todos.length;
    final completed = todos.where((t) => t.isCompleted).length;
    final pending = todos.where((t) => !t.isCompleted).length;
    final overdue = todos.where((t) => t.isOverdue).length;
    final today = todos.where((t) => t.isDueToday).length;
    final important =
        todos.where((t) => t.isImportant && !t.isCompleted).length;

    final byPriority = <TodoPriority, int>{};
    final byCategory = <TodoCategory, int>{};

    for (final priority in TodoPriority.values) {
      byPriority[priority] =
          todos.where((t) => t.priority == priority && !t.isCompleted).length;
    }

    for (final category in TodoCategory.values) {
      byCategory[category] =
          todos.where((t) => t.category == category && !t.isCompleted).length;
    }

    return TodoStats(
      total: total,
      completed: completed,
      pending: pending,
      overdue: overdue,
      today: today,
      important: important,
      byPriority: byPriority,
      byCategory: byCategory,
    );
  }
}


enum TodoFilter { all, pending, completed, today, overdue, important }

enum TodoSort { dueDate, priority, created, alphabetical }


class TodoStats {
  final int total;
  final int completed;
  final int pending;
  final int overdue;
  final int today;
  final int important;
  final Map<TodoPriority, int> byPriority;
  final Map<TodoCategory, int> byCategory;

  const TodoStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.today,
    required this.important,
    required this.byPriority,
    required this.byCategory,
  });
}

class TodoNotifier extends StateNotifier<TodoState> {
  final _supabase = SupabaseClientHelper.supabase;
  StreamSubscription? _todosSubscription;
  final Ref _ref;

  TodoNotifier(this._ref) : super(const TodoState(isLoading: true)) {
    _ref.listen(authUserProvider, (previous, next) {
      if (next.valueOrNull == null) {
        clearTodos();
      } else if (previous?.valueOrNull?.id != next.valueOrNull?.id) {
        fetchTodos();
      }
    });

    fetchTodos();
  }

  void clearTodos() {
    _todosSubscription?.cancel();
    _todosSubscription = null;
    state = const TodoState(todos: [], isLoading: false);
  }

  @override
  void dispose() {
    _todosSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchTodos() async {
    try {
      state = state.copyWith(isLoading: true);
      final userId = SupabaseClientHelper.userId;
      debugPrint("Current user ID when fetching todos: $userId");

      if (userId == null) {
        state = state.copyWith(todos: [], isLoading: false);
        return;
      }

      _todosSubscription?.cancel();

      final data = await _supabase
          .from('notes') // Your table name
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      debugPrint("Fetched todos count: ${data.length}");

      final todos = data
          .map<Todo>((item) => Todo.fromMap(item, item['id'].toString()))
          .toList();

      state = state.copyWith(todos: todos, isLoading: false);

      _setupTodosSubscription(userId);
    } catch (e) {
      debugPrint("Error fetching todos: $e");
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void _setupTodosSubscription(String userId) {
    _todosSubscription?.cancel();
    _todosSubscription = _supabase
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('owner_id', userId)
        .listen((data) {
          if (data.isNotEmpty) {
            final todos = data
                .map<Todo>((item) => Todo.fromMap(item, item['id'].toString()))
                .toList();

            todos.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            state = state.copyWith(todos: todos);
          }
        }, onError: (error) {
          debugPrint("Subscription error: $error");
        });
  }

  Future<void> addTodo(Todo todo) async {
    try {
      final userId = SupabaseClientHelper.userId;
      if (userId == null) {
        throw Exception("No authenticated user found");
      }

      final todoWithUpdatedFields = todo.copyWith(
        ownerId: userId,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        dueDate: todo.dueDate,
      );

      final optimisticTodo = todoWithUpdatedFields.copyWith(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      );

      state = state.copyWith(
        todos: [optimisticTodo, ...state.todos],
      );

      final res = await _supabase
          .from('notes')
          .insert(todoWithUpdatedFields.toMap())
          .select();

      if (res.isNotEmpty) {
        final newTodo = Todo.fromMap(res.first, res.first['id'].toString());

        state = state.copyWith(
          todos: state.todos
              .map((t) => t.id == optimisticTodo.id ? newTodo : t)
              .toList(),
        );
      }
    } catch (e) {
      state = state.copyWith(
          todos: state.todos.where((t) => !t.id.startsWith('temp-')).toList(),
          error: e.toString());
      Fluttertoast.showToast(
        msg: "Failed to add todo: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> updateTodo(Todo todo) async {
    try {
      final updatedTodo = todo.copyWith(
        updatedAt: DateTime.now().toIso8601String(),
      );

      state = state.copyWith(
        todos:
            state.todos.map((t) => t.id == todo.id ? updatedTodo : t).toList(),
      );

      await _supabase
          .from('notes')
          .update(updatedTodo.toMap())
          .eq('id', todo.id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      fetchTodos();

      Fluttertoast.showToast(
        msg: "Failed to update todo: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      state = state.copyWith(
        todos: state.todos.where((todo) => todo.id != id).toList(),
      );

      await _supabase.from('notes').delete().eq('id', id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      fetchTodos();

      Fluttertoast.showToast(
        msg: "Failed to delete todo: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> toggleTodoCompletion(Todo todo) async {
    try {
      final updatedTodo = todo.copyWith(
        isCompleted: !todo.isCompleted,
        updatedAt: DateTime.now().toIso8601String(),
      );

      state = state.copyWith(
        todos:
            state.todos.map((t) => t.id == todo.id ? updatedTodo : t).toList(),
      );

      await _supabase.from('notes').update({
        'is_completed': updatedTodo.isCompleted,
        'updated_at': updatedTodo.updatedAt
      }).eq('id', todo.id);

      if (updatedTodo.isCompleted) {
        Fluttertoast.showToast(
          msg: "Todo marked as completed! 🎉",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      fetchTodos();

      Fluttertoast.showToast(
        msg: "Failed to update todo: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> toggleImportant(Todo todo) async {
    try {
      final updatedTodo = todo.copyWith(
        isImportant: !todo.isImportant,
        updatedAt: DateTime.now().toIso8601String(),
      );

      state = state.copyWith(
        todos:
            state.todos.map((t) => t.id == todo.id ? updatedTodo : t).toList(),
      );

      await _supabase.from('notes').update({
        'is_important': updatedTodo.isImportant,
        'updated_at': updatedTodo.updatedAt
      }).eq('id', todo.id);

      Fluttertoast.showToast(
        msg: updatedTodo.isImportant
            ? "Todo marked as important ⭐"
            : "Todo unmarked as important",
        backgroundColor: updatedTodo.isImportant ? Colors.orange : Colors.grey,
        textColor: Colors.white,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      fetchTodos();

      Fluttertoast.showToast(
        msg: "Failed to update todo: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  // Filter and sort methods
  void setFilter(TodoFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSort(TodoSort sort) {
    state = state.copyWith(sort: sort);
  }

  // Get todos by specific criteria
  List<Todo> getTodosByCategory(TodoCategory category) {
    return state.todos
        .where((todo) => todo.category == category && !todo.isCompleted)
        .toList();
  }

  List<Todo> getTodosByPriority(TodoPriority priority) {
    return state.todos
        .where((todo) => todo.priority == priority && !todo.isCompleted)
        .toList();
  }

  List<Todo> getOverdueTodos() {
    return state.todos.where((todo) => todo.isOverdue).toList();
  }

  List<Todo> getTodaysTodos() {
    return state.todos.where((todo) => todo.isDueToday).toList();
  }

  List<Todo> getImportantTodos() {
    return state.todos
        .where((todo) => todo.isImportant && !todo.isCompleted)
        .toList();
  }

  // Batch operations
  Future<void> markAllAsCompleted(List<Todo> todos) async {
    try {
      final updates = <Future>[];

      for (final todo in todos) {
        if (!todo.isCompleted) {
          final updatedTodo = todo.copyWith(
            isCompleted: true,
            updatedAt: DateTime.now().toIso8601String(),
          );

          updates.add(_supabase.from('notes').update({
            'is_completed': true,
            'updated_at': updatedTodo.updatedAt
          }).eq('id', todo.id));
        }
      }

      await Future.wait(updates);

      // Update local state
      state = state.copyWith(
        todos: state.todos.map((t) {
          if (todos.any((todo) => todo.id == t.id)) {
            return t.copyWith(isCompleted: true);
          }
          return t;
        }).toList(),
      );

      Fluttertoast.showToast(
        msg: "All todos marked as completed! 🎉",
        backgroundColor: Colors.green,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to update todos: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> deleteCompletedTodos() async {
    try {
      final completedTodos = state.todos.where((t) => t.isCompleted).toList();
      final deletions = <Future>[];

      for (final todo in completedTodos) {
        deletions.add(_supabase.from('notes').delete().eq('id', todo.id));
      }

      await Future.wait(deletions);

      state = state.copyWith(
        todos: state.todos.where((t) => !t.isCompleted).toList(),
      );

      Fluttertoast.showToast(
        msg: "Completed todos deleted",
        backgroundColor: Colors.blue,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to delete todos: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }
}

// Updated provider
final todoProvider = StateNotifierProvider<TodoNotifier, TodoState>((ref) {
  return TodoNotifier(ref);
});

// Convenience providers
final filteredTodosProvider = Provider<List<Todo>>((ref) {
  final state = ref.watch(todoProvider);
  return state.filteredTodos;
});

final todoStatsProvider = Provider<TodoStats>((ref) {
  final state = ref.watch(todoProvider);
  return state.stats;
});

final overdueTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoProvider).todos;
  return todos.where((todo) => todo.isOverdue).toList();
});

final todaysTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoProvider).todos;
  return todos.where((todo) => todo.isDueToday).toList();
});

final importantTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoProvider).todos;
  return todos.where((todo) => todo.isImportant && !todo.isCompleted).toList();
});
