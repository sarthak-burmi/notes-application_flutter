import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:notes_app_solulab/core/supaBase_client.dart';
import 'package:notes_app_solulab/model/notesModel.dart';
import 'package:notes_app_solulab/provider/auth_provider.dart';

// Notes state
class NotesState {
  final List<Note> notes;
  final bool isLoading;
  final String? error;

  const NotesState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
  });

  NotesState copyWith({
    List<Note>? notes,
    bool? isLoading,
    String? error,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notes notifier
class NotesNotifier extends StateNotifier<NotesState> {
  final _supabase = SupabaseClientHelper.supabase;
  StreamSubscription? _notesSubscription;
  final Ref _ref;

  NotesNotifier(this._ref) : super(const NotesState(isLoading: true)) {
    // Listen to auth changes to trigger note refresh
    _ref.listen(authUserProvider, (previous, next) {
      // Clear notes when logging out or changing users
      if (next.valueOrNull == null) {
        clearNotes();
      } else if (previous?.valueOrNull?.id != next.valueOrNull?.id) {
        // If user changed, refetch notes
        fetchNotes();
      }
    });

    // Initial fetch
    fetchNotes();
  }

  void clearNotes() {
    _notesSubscription?.cancel();
    _notesSubscription = null;
    state = const NotesState(notes: [], isLoading: false);
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }

  // Fetch all notes for current user
  Future<void> fetchNotes() async {
    try {
      state = state.copyWith(isLoading: true);
      final userId = SupabaseClientHelper.userId;
      debugPrint("Current user ID when fetching notes: $userId"); // Debug

      if (userId == null) {
        state = state.copyWith(notes: [], isLoading: false);
        return;
      }

      // Cancel any existing subscription
      _notesSubscription?.cancel();

      // Get initial data
      final data = await _supabase
          .from('notes')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      debugPrint("Fetched notes count: ${data.length}"); // Debug

      final notes = data
          .map<Note>((item) => Note.fromMap(item, item['id'].toString()))
          .toList();

      state = state.copyWith(notes: notes, isLoading: false);

      // Setup real-time subscription for future updates
      _setupNotesSubscription(userId);
    } catch (e) {
      debugPrint("Error fetching notes: $e"); // Debug
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
                .map<Note>((item) => Note.fromMap(item, item['id'].toString()))
                .toList();

            // Sort by creation date (newest first)
            notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            state = state.copyWith(notes: notes);
          }
        }, onError: (error) {
          debugPrint("Subscription error: $error");
          // Don't update state here, just log the error
        });
  }

  // Add new note
  Future<void> addNote(Note note) async {
    try {
      // Verify the owner ID is set properly
      final userId = SupabaseClientHelper.userId;
      if (userId == null) {
        throw Exception("No authenticated user found");
      }

      // Ensure the note has the correct owner_id and dates
      final noteWithUpdatedFields = note.copyWith(
        ownerId: userId,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        taskDate: note.taskDate ??
            DateTime.now()
                .toIso8601String(), // Use provided task date or fallback to now
      );

      // Optimistically update the UI
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
        final newNote = Note.fromMap(res.first, res.first['id'].toString());

        // Replace the optimistic note with the real one
        state = state.copyWith(
          notes: state.notes
              .map((n) => n.id == optimisticNote.id ? newNote : n)
              .toList(),
        );
      }
    } catch (e) {
      // Remove the optimistic note if there was an error
      state = state.copyWith(
          notes: state.notes.where((n) => !n.id.startsWith('temp-')).toList(),
          error: e.toString());
      Fluttertoast.showToast(
        msg: "Failed to add note: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  // Update existing note
  Future<void> updateNote(Note note) async {
    try {
      final updatedNote = note.copyWith(
        updatedAt: DateTime.now().toIso8601String(),
      );

      // Optimistically update the UI
      state = state.copyWith(
        notes:
            state.notes.map((n) => n.id == note.id ? updatedNote : n).toList(),
      );

      await _supabase
          .from('notes')
          .update(updatedNote.toMap())
          .eq('id', note.id);
    } catch (e) {
      // Revert to original state if there was an error
      state = state.copyWith(error: e.toString());

      // Refresh notes to ensure UI is in sync with server
      fetchNotes();

      Fluttertoast.showToast(
        msg: "Failed to update note: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  // Delete note
  Future<void> deleteNote(String id) async {
    try {
      // Store the note before removing it
      final deletedNote = state.notes.firstWhere((note) => note.id == id);
      final noteIndex = state.notes.indexWhere((note) => note.id == id);

      // Optimistically update the UI
      state = state.copyWith(
        notes: state.notes.where((note) => note.id != id).toList(),
      );

      await _supabase.from('notes').delete().eq('id', id);
    } catch (e) {
      // If deletion fails, show error and refresh notes
      state = state.copyWith(error: e.toString());
      fetchNotes();

      Fluttertoast.showToast(
        msg: "Failed to delete note: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  // Toggle note completion status
  Future<void> toggleNoteCompletion(Note note) async {
    try {
      final updatedNote = note.copyWith(
        isCompleted: !note.isCompleted,
        updatedAt: DateTime.now().toIso8601String(),
      );

      // Optimistically update the UI
      state = state.copyWith(
        notes:
            state.notes.map((n) => n.id == note.id ? updatedNote : n).toList(),
      );

      await _supabase.from('notes').update({
        'is_completed': updatedNote.isCompleted,
        'updated_at': updatedNote.updatedAt
      }).eq('id', note.id);

      // Show toast if completed
      if (updatedNote.isCompleted) {
        Fluttertoast.showToast(
          msg: "Task marked as completed",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      // Revert to original state if there was an error
      state = state.copyWith(error: e.toString());

      // Refresh notes to ensure UI is in sync with server
      fetchNotes();

      Fluttertoast.showToast(
        msg: "Failed to update task: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }
}

// Notes provider
final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  return NotesNotifier(ref);
});
