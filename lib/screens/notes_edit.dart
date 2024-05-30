import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notes_app_solulab/constants/colors.dart';
import 'package:provider/provider.dart';
import 'package:notes_app_solulab/model/notesModel.dart';
import 'package:notes_app_solulab/provider/notes_provider.dart';

class NoteEdit extends StatelessWidget {
  final Note note;

  NoteEdit({required this.note});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    TextEditingController _titleController =
        TextEditingController(text: note.title);
    TextEditingController _contentController =
        TextEditingController(text: note.content);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          note.id.isEmpty ? 'Add Task' : 'Edit Task',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.03),
          child: Column(
            children: [
              Image.asset(
                "assets/images/add_notes-bro.png",
                height: height * 0.50,
              ),
              SizedBox(height: height * 0.04),
              TextFormField(
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 18,
                ),
                controller: _titleController,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: addTaskColor, width: 2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: 'Title',
                  labelStyle: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                onChanged: (value) {
                  note.title = value;
                },
              ),
              SizedBox(height: height * 0.04),
              TextField(
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 18,
                ),
                controller: _contentController,
                onChanged: (value) {
                  note.content = value;
                },
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: addTaskColor, width: 2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: 'Content',
                  labelStyle: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ),
              SizedBox(height: height * 0.02),
              SizedBox(
                width: width * 0.8,
                height: height * 0.05,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: completedTask,
                  ),
                  onPressed: () {
                    note.title = _titleController.text;
                    note.content = _contentController.text;
                    if (note.id.isEmpty) {
                      note.ownerId = FirebaseAuth.instance.currentUser!.uid;
                      Provider.of<NoteProvider>(context, listen: false)
                          .addNote(note);
                    } else {
                      Provider.of<NoteProvider>(context, listen: false)
                          .updateNote(note);
                    }
                    Navigator.pop(context);
                  },
                  child: Text(
                    note.id.isEmpty ? 'Add' : 'Save',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: 19,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
