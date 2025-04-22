import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:notes_app_solulab/core/supaBase_client.dart';
import 'package:notes_app_solulab/functions/auth_provider.dart';
import 'package:notes_app_solulab/model/TaskModel.dart';

class TaskState {
  final List<Task> notes;
  final bool isLoading;
  final String? error;

  const TaskState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
  });

  TaskState copyWith({
    List<Task>? notes,
    bool? isLoading,
    String? error,
  }) {
    return TaskState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotesNotifier extends StateNotifier<TaskState> {
  final _supabase = SupabaseClientHelper.supabase;
  StreamSubscription? _notesSubscription;
  final Ref _ref;

  NotesNotifier(this._ref) : super(const TaskState(isLoading: true)) {
    _ref.listen(authUserProvider, (previous, next) {
      if (next.valueOrNull == null) {
        clearNotes();
      } else if (previous?.valueOrNull?.id != next.valueOrNull?.id) {
        fetchNotes();
      }
    });

    fetchNotes();
  }

  void clearNotes() {
    _notesSubscription?.cancel();
    _notesSubscription = null;
    state = const TaskState(notes: [], isLoading: false);
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchNotes() async {
    try {
      state = state.copyWith(isLoading: true);
      final userId = SupabaseClientHelper.userId;
      debugPrint("Current user ID when fetching notes: $userId");

      if (userId == null) {
        state = state.copyWith(notes: [], isLoading: false);
        return;
      }

      _notesSubscription?.cancel();

      final data = await _supabase
          .from('notes')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      debugPrint("Fetched notes count: ${data.length}");

      final notes = data
          .map<Task>((item) => Task.fromMap(item, item['id'].toString()))
          .toList();

      state = state.copyWith(notes: notes, isLoading: false);

      _setupNotesSubscription(userId);
    } catch (e) {
      debugPrint("Error fetching notes: $e");
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void _setupNotesSubscription(String userId) {
    _notesSubscription?.cancel();
    _notesSubscription = _supabase
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('owner_id', userId)
        .listen((data) {
          if (data.isNotEmpty) {
            final notes = data
                .map<Task>((item) => Task.fromMap(item, item['id'].toString()))
                .toList();

            notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            state = state.copyWith(notes: notes);
          }
        }, onError: (error) {
          debugPrint("Subscription error: $error");
        });
  }

  Future<void> addNote(Task task) async {
    try {
      final userId = SupabaseClientHelper.userId;
      if (userId == null) {
        throw Exception("No authenticated user found");
      }

      final noteWithUpdatedFields = task.copyWith(
        ownerId: userId,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        taskDate: task.taskDate ?? DateTime.now().toIso8601String(),
      );

      final optimisticNote = noteWithUpdatedFields.copyWith(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      );

      state = state.copyWith(
        notes: [optimisticNote, ...state.notes],
      );

      final res = await _supabase
          .from('notes')
          .insert(noteWithUpdatedFields.toMap())
          .select();

      if (res.isNotEmpty) {
        final newNote = Task.fromMap(res.first, res.first['id'].toString());

        state = state.copyWith(
          notes: state.notes
              .map((n) => n.id == optimisticNote.id ? newNote : n)
              .toList(),
        );
      }
    } catch (e) {
      state = state.copyWith(
          notes: state.notes.where((n) => !n.id.startsWith('temp-')).toList(),
          error: e.toString());
      Fluttertoast.showToast(
        msg: "Failed to add note: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> updateNote(Task note) async {
    try {
      final updatedNote = note.copyWith(
        updatedAt: DateTime.now().toIso8601String(),
      );

      state = state.copyWith(
        notes:
            state.notes.map((n) => n.id == note.id ? updatedNote : n).toList(),
      );

      await _supabase
          .from('notes')
          .update(updatedNote.toMap())
          .eq('id', note.id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      fetchNotes();

      Fluttertoast.showToast(
        msg: "Failed to update note: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      final deletedNote = state.notes.firstWhere((note) => note.id == id);
      final noteIndex = state.notes.indexWhere((note) => note.id == id);

      state = state.copyWith(
        notes: state.notes.where((note) => note.id != id).toList(),
      );

      await _supabase.from('notes').delete().eq('id', id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      fetchNotes();

      Fluttertoast.showToast(
        msg: "Failed to delete note: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> toggleNoteCompletion(Task note) async {
    try {
      final updatedNote = note.copyWith(
        isCompleted: !note.isCompleted,
        updatedAt: DateTime.now().toIso8601String(),
      );

      state = state.copyWith(
        notes:
            state.notes.map((n) => n.id == note.id ? updatedNote : n).toList(),
      );

      await _supabase.from('notes').update({
        'is_completed': updatedNote.isCompleted,
        'updated_at': updatedNote.updatedAt
      }).eq('id', note.id);

      if (updatedNote.isCompleted) {
        Fluttertoast.showToast(
          msg: "Task marked as completed",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());

      fetchNotes();

      Fluttertoast.showToast(
        msg: "Failed to update task: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }
}

final taskProvider = StateNotifierProvider<NotesNotifier, TaskState>((ref) {
  return NotesNotifier(ref);
});
