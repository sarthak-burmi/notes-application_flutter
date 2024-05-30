import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:notes_app_solulab/autherntication/Login.dart';
import 'package:notes_app_solulab/constants/colors.dart';
import 'package:notes_app_solulab/constants/timeGreeting.dart';
import 'package:provider/provider.dart';
import 'package:notes_app_solulab/screens/notes_edit.dart';
import 'package:notes_app_solulab/model/notesModel.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app_solulab/provider/notes_provider.dart';

class NoteList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    final user = FirebaseAuth.instance.currentUser;
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('MMMM d, yyyy').format(now);
    String weekday = DateFormat('EEEE').format(now);

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<NoteProvider>(
      builder: (context, noteProvider, _) {
        if (noteProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              SizedBox(height: height * 0.04),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.03),
                child: Row(
                  children: [
                    Text(
                      'Notes',
                      style: GoogleFonts.montserrat(
                        color: Colors.black,
                        fontSize: 45,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Fluttertoast.showToast(
                          msg: "Logged Out",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                        FirebaseAuth.instance.signOut();
                        Provider.of<NoteProvider>(context, listen: false)
                            .fetchNotes();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      },
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: height * 0.01),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.03),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TimeGreetingScreen(),
                    Row(
                      children: [
                        Text(
                          "$formattedDate,",
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          weekday,
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: height * 0.01),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.03),
                  child: _buildNotesList(noteProvider),
                ),
              ),
            ],
          ),
          floatingActionButton:
              _buildAddNoteButton(context, noteProvider, user),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
      },
    );
  }

  Widget _buildNoteItem(
      BuildContext context, NoteProvider noteProvider, Note note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            width: 0.99,
            color: Colors.grey.shade200,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(5),
          child: ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () =>
                      _confirmDelete(context, noteProvider, note.id),
                  icon: const Icon(
                    CupertinoIcons.delete,
                    size: 25,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    note.content,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        value: noteProvider,
                        child: NoteEdit(note: note),
                      ),
                    ),
                  ),
                  icon: const Icon(
                    CupertinoIcons.pencil,
                    size: 30,
                    color: mainColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, NoteProvider noteProvider, String noteId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                noteProvider.deleteNote(noteId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddNoteButton(
      BuildContext context, NoteProvider noteProvider, User user) {
    return FloatingActionButton(
      backgroundColor: mainColor,
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: noteProvider,
            child: NoteEdit(
              note: Note(
                id: '',
                title: '',
                content: '',
                ownerId: user.uid,
              ),
            ),
          ),
        ),
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
      ),
    );
  }

  Widget _buildNotesList(NoteProvider noteProvider) {
    if (noteProvider.notes.isEmpty) {
      return Center(
        child: Column(
          children: [
            Image.asset(
                "assets/images/Oops! 404 Error with a broken robot-rafiki.png"),
            Text(
              'No notes available.',
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: 30,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: noteProvider.notes.length,
      itemBuilder: (context, index) {
        final note = noteProvider.notes[index];
        return _buildNoteItem(context, noteProvider, note);
      },
    );
  }
}
