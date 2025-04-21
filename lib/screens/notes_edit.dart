import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:notes_app_solulab/constants/colors.dart';
import 'package:notes_app_solulab/model/notesModel.dart';
import 'package:notes_app_solulab/provider/notes_provider.dart';

class NoteEdit extends ConsumerStatefulWidget {
  final Note note;

  const NoteEdit({Key? key, required this.note}) : super(key: key);

  @override
  ConsumerState<NoteEdit> createState() => _NoteEditState();
}

class _NoteEditState extends ConsumerState<NoteEdit>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late bool _isCompleted;
  late DateTime _selectedDate;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _isCompleted = widget.note.isCompleted;

    // Parse the task date or use current date
    _selectedDate = DateTime.tryParse(widget.note.taskDate) ?? DateTime.now();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Date selection method
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: mainColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: mainColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Title and content cannot be empty',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final updatedNote = widget.note.copyWith(
      title: title,
      content: content,
      isCompleted: _isCompleted,
      taskDate: _selectedDate.toIso8601String(), // Update task date
    );

    try {
      if (widget.note.id.isEmpty) {
        // Add new note
        await ref.read(notesProvider.notifier).addNote(updatedNote);
        if (mounted) {
          Fluttertoast.showToast(
            msg: "Task added successfully",
            backgroundColor: Colors.black87,
          );
        }
      } else {
        // Update existing note
        await ref.read(notesProvider.notifier).updateNote(updatedNote);
        if (mounted) {
          Fluttertoast.showToast(
            msg: "Task updated successfully",
            backgroundColor: Colors.black87,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing calculations
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        // Calculate responsive padding and spacing
        double horizontalPadding =
            maxWidth > 600 ? maxWidth * 0.1 : maxWidth * 0.05;
        double verticalSpacing =
            maxHeight > 800 ? maxHeight * 0.03 : maxHeight * 0.02;

        // Responsive image height
        double imageHeight =
            maxHeight > 800 ? maxHeight * 0.25 : maxHeight * 0.2;

        // Responsive text scaling
        double responsiveFontSize(double baseSize) {
          return maxWidth > 600 ? baseSize : baseSize * (maxWidth / 600);
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              widget.note.id.isEmpty ? 'Add Task' : 'Edit Task',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: responsiveFontSize(18),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            elevation: 0,
            actions: [
              if (!widget.note.id.isEmpty)
                IconButton(
                  onPressed: () {
                    _confirmDelete(context);
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: verticalSpacing),
                        Center(
                          child: Hero(
                            tag: 'note_image',
                            child: Image.asset(
                              "assets/images/add_notes-bro.png",
                              height: imageHeight,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(height: verticalSpacing),

                        // Task Date Selection
                        _buildSectionTitle(
                            context, "Task Date", responsiveFontSize(16)),
                        SizedBox(height: verticalSpacing * 0.5),
                        _buildDateSelector(
                            context, responsiveFontSize(16), maxWidth),
                        SizedBox(height: verticalSpacing),

                        // Title Input
                        _buildSectionTitle(
                            context, "Title", responsiveFontSize(16)),
                        SizedBox(height: verticalSpacing * 0.5),
                        _buildTitleInput(context, responsiveFontSize(16)),
                        SizedBox(height: verticalSpacing),

                        // Description Input
                        _buildSectionTitle(
                            context, "Description", responsiveFontSize(16)),
                        SizedBox(height: verticalSpacing * 0.5),
                        _buildDescriptionInput(context, responsiveFontSize(16)),
                        SizedBox(height: verticalSpacing),

                        // Completed Task Checkbox
                        _buildCompletedTaskToggle(context),
                        SizedBox(height: verticalSpacing),

                        // Save Button
                        _buildSaveButton(
                            context, responsiveFontSize(18), maxWidth),
                        SizedBox(height: verticalSpacing * 0.5),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper methods to break down the build method
  Widget _buildSectionTitle(
      BuildContext context, String title, double fontSize) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        color: Colors.black87,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDateSelector(
      BuildContext context, double fontSize, double maxWidth) {
    final formattedDate = DateFormat('MMM d, yyyy').format(_selectedDate);

    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            horizontal: maxWidth > 600 ? 20 : 15, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: mainColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              formattedDate,
              style: GoogleFonts.montserrat(
                fontSize: fontSize,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_calendar,
                color: Colors.grey.shade700,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleInput(BuildContext context, double fontSize) {
    return TextFormField(
      style: GoogleFonts.montserrat(
        color: Colors.black,
        fontSize: fontSize,
      ),
      controller: _titleController,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: mainColor, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: 'Enter task title',
        hintStyle: GoogleFonts.montserrat(
          color: Colors.grey,
          fontSize: fontSize,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDescriptionInput(BuildContext context, double fontSize) {
    return TextField(
      style: GoogleFonts.montserrat(
        color: Colors.black,
        fontSize: fontSize,
      ),
      controller: _contentController,
      maxLines: 5,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: mainColor, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: 'Enter task description',
        hintStyle: GoogleFonts.montserrat(
          color: Colors.grey,
          fontSize: fontSize,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildCompletedTaskToggle(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _isCompleted = !_isCompleted;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: _isCompleted,
                  activeColor: completedTask,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: BorderSide(
                    width: 1.5,
                    color: _isCompleted ? completedTask : Colors.grey.shade400,
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      _isCompleted = value ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Mark as completed',
                style: GoogleFonts.montserrat(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_isCompleted) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_circle_outline,
                  color: completedTask,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(
      BuildContext context, double fontSize, double maxWidth) {
    return SizedBox(
      width: double.infinity,
      height: maxWidth > 600 ? 60 : 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: mainColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isLoading ? null : _saveNote,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                widget.note.id.isEmpty ? 'Add Task' : 'Save Changes',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Task',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this task?',
            style: GoogleFonts.montserrat(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: Colors.black54,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                ),
              ),
              onPressed: () async {
                await ref
                    .read(notesProvider.notifier)
                    .deleteNote(widget.note.id);
                if (mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Fluttertoast.showToast(
                    msg: "Task deleted successfully",
                    backgroundColor: Colors.black87,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
