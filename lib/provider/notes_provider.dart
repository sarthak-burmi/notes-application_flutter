import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notes_app_solulab/model/notesModel.dart';

class NoteProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User user;
  List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  NoteProvider(this.user) {
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    _isLoading = true;
    notifyListeners(); // Notify listeners to show loading indicator
    try {
      final snapshot = await _db
          .collection('notes')
          .where('ownerId', isEqualTo: user.uid)
          .get();
      _notes =
          snapshot.docs.map((doc) => Note.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error fetching notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners after fetching notes
    }
  }

  Future<void> addNote(Note note) async {
    try {
      await _db.collection('notes').add(note.toMap());
      fetchNotes(); // Fetch notes again after adding a new note
    } catch (e) {
      print('Error adding note: $e');
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      await _db.collection('notes').doc(note.id).update(note.toMap());
      fetchNotes(); // Fetch notes again after updating a note
    } catch (e) {
      print('Error updating note: $e');
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _db.collection('notes').doc(id).delete();
      fetchNotes(); // Fetch notes again after deleting a note
    } catch (e) {
      print('Error deleting note: $e');
    }
  }
}
