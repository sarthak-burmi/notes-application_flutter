import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:notes_app_solulab/constants/colors.dart';
import 'package:notes_app_solulab/model/notesModel.dart';
import 'package:notes_app_solulab/provider/auth_provider.dart';
import 'package:notes_app_solulab/provider/notes_provider.dart';

class AddNoteScreen extends ConsumerStatefulWidget {
  const AddNoteScreen({super.key});

  @override
  ConsumerState<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends ConsumerState<AddNoteScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isCompleted = false;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

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

    // Get current user ID
    final userId = ref.read(authUserProvider).value?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You need to be logged in to add notes',
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

    try {
      // Create new note with task date as ISO string
      final newNote = Note(
        id: '',
        title: title,
        content: content,
        ownerId: userId,
        isCompleted: _isCompleted,
        // Use ISO 8601 format for database storage
        taskDate: _selectedDate.toIso8601String(),
      );

      // Add note using provider
      await ref.read(notesProvider.notifier).addNote(newNote);

      // Show success toast
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Task added successfully",
          backgroundColor: Colors.black87,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error toast
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get screen size
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // Calculate responsive values based on screen size
    final bool isSmallScreen = width < 360;
    final bool isTablet = width > 600;
    final bool isLargeScreen = width > 900;

    // Calculate adaptive paddings and sizes
    final horizontalPadding = width *
        (isSmallScreen
            ? 0.03
            : isTablet
                ? 0.08
                : 0.05);
    final verticalSpacing = height * 0.015;
    final largeVerticalSpacing = height * 0.025;
    final buttonHeight = height * (isSmallScreen ? 0.055 : 0.06);

    // Responsive font sizes
    final double titleFontSize = isSmallScreen
        ? 14
        : isTablet
            ? 18
            : 16;
    final double contentFontSize = isSmallScreen
        ? 14
        : isTablet
            ? 18
            : 16;
    final double labelFontSize = isSmallScreen
        ? 14
        : isTablet
            ? 18
            : 16;
    final double buttonFontSize = isSmallScreen
        ? 16
        : isTablet
            ? 20
            : 18;

    // Responsive image height
    final imageHeight = height *
        (isSmallScreen
            ? 0.2
            : isTablet
                ? 0.3
                : 0.25);

    // Format the selected date
    final formattedDate = DateFormat('MMM d, yyyy').format(_selectedDate);

    // Create adaptive layout based on screen orientation
    final isLandscape = width > height;
    final contentWidget = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: verticalSpacing),

            // Conditionally show image based on available space
            if (!isLandscape || isLargeScreen)
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

            if (!isLandscape || isLargeScreen)
              SizedBox(height: largeVerticalSpacing),

            // Task Date Selection
            Text(
              "Task Date",
              style: GoogleFonts.montserrat(
                color: Colors.black87,
                fontSize: labelFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: verticalSpacing * 0.5),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.04,
                  vertical: height * 0.017,
                ),
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
                      size: isSmallScreen ? 16 : 20,
                    ),
                    SizedBox(width: width * 0.03),
                    Text(
                      formattedDate,
                      style: GoogleFonts.montserrat(
                        fontSize: contentFontSize,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 4 : 5),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_calendar,
                        color: Colors.grey.shade700,
                        size: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: largeVerticalSpacing),

            // Title field
            Text(
              "Title",
              style: GoogleFonts.montserrat(
                color: Colors.black87,
                fontSize: labelFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: verticalSpacing * 0.5),
            TextFormField(
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: contentFontSize,
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
                  fontSize: contentFontSize,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: width * 0.04,
                  vertical: height * 0.017,
                ),
              ),
            ),
            SizedBox(height: largeVerticalSpacing),

            // Description field
            Text(
              "Description",
              style: GoogleFonts.montserrat(
                color: Colors.black87,
                fontSize: labelFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: verticalSpacing * 0.5),
            TextField(
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: contentFontSize,
              ),
              controller: _contentController,
              maxLines: isLandscape ? 3 : 5,
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
                  fontSize: contentFontSize,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: width * 0.04,
                  vertical: height * 0.017,
                ),
              ),
            ),
            SizedBox(height: largeVerticalSpacing),

            // Completed checkbox
            Container(
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
                  padding: EdgeInsets.symmetric(
                    vertical: height * 0.015,
                    horizontal: width * 0.04,
                  ),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: isSmallScreen ? 1.0 : 1.1,
                        child: Checkbox(
                          value: _isCompleted,
                          activeColor: completedTask,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          side: BorderSide(
                            width: 1.5,
                            color: _isCompleted
                                ? completedTask
                                : Colors.grey.shade400,
                          ),
                          onChanged: (bool? value) {
                            setState(() {
                              _isCompleted = value ?? false;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: width * 0.03),
                      Text(
                        'Mark as completed',
                        style: GoogleFonts.montserrat(
                          color: Colors.black87,
                          fontSize: contentFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_isCompleted) ...[
                        SizedBox(width: width * 0.02),
                        Icon(
                          Icons.check_circle_outline,
                          color: completedTask,
                          size: isSmallScreen ? 18 : 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: largeVerticalSpacing),

            // Add button
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
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
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Add Task',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            SizedBox(height: largeVerticalSpacing),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Add Task',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: isSmallScreen ? 18 : 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: isLandscape && isTablet
                  ? Row(
                      children: [
                        // In landscape and tablet, show image on the left
                        if (isLargeScreen)
                          Expanded(
                            flex: 3,
                            child: Center(
                              child: Hero(
                                tag: 'note_image',
                                child: Image.asset(
                                  "assets/images/add_notes-bro.png",
                                  height: height * 0.6,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        // Form on the right side
                        Expanded(
                          flex: 7,
                          child: contentWidget,
                        ),
                      ],
                    )
                  : contentWidget,
            ),
          ),
        ),
      ),
    );
  }
}
