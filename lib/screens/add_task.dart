import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:notes_app_solulab/constants/colors.dart';
import 'package:notes_app_solulab/functions/auth_provider.dart';
import 'package:notes_app_solulab/functions/task_provider.dart';
import 'package:notes_app_solulab/model/TaskModel.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen>
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
    final ThemeData theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.brightness == Brightness.light
                ? ColorScheme.light(
                    primary: mainColor,
                    onPrimary: Colors.white,
                    onSurface: textColor,
                  )
                : ColorScheme.dark(
                    primary: mainColor,
                    onPrimary: Colors.white,
                    onSurface: Colors.white,
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
          backgroundColor: deleteColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final userId = ref.read(authUserProvider).value?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You need to be logged in to add notes',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: deleteColor,
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
      final newNote = Task(
        id: '',
        title: title,
        content: content,
        ownerId: userId,
        isCompleted: _isCompleted,
        taskDate: _selectedDate.toIso8601String(),
      );

      await ref.read(taskProvider.notifier).addNote(newNote);

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: deleteColor,
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
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final width = size.width;
    final height = size.height;
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final bool isSmallScreen = width < 360;
    final bool isTablet = width > 600;
    final bool isLargeScreen = width > 900;

    final horizontalPadding = width *
        (isSmallScreen
            ? 0.03
            : isTablet
                ? 0.08
                : 0.05);
    final verticalSpacing = height * 0.015;
    final largeVerticalSpacing = height * 0.025;
    final buttonHeight = height * (isSmallScreen ? 0.055 : 0.06);

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

    final imageHeight = height *
        (isSmallScreen
            ? 0.2
            : isTablet
                ? 0.3
                : 0.25);

    final formattedDate = DateFormat('MMM d, yyyy').format(_selectedDate);

    final isLandscape = width > height;
    final contentWidget = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: verticalSpacing),
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
            Text(
              "Task Date",
              style: GoogleFonts.montserrat(
                color: theme.textTheme.bodyLarge?.color,
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
                  color: isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade300),
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
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 4 : 5),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_calendar,
                        color: isDarkMode
                            ? Colors.grey.shade500
                            : Colors.grey.shade700,
                        size: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: largeVerticalSpacing),
            Text(
              "Title",
              style: GoogleFonts.montserrat(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: labelFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: verticalSpacing * 0.5),
            TextFormField(
              style: GoogleFonts.montserrat(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: contentFontSize,
              ),
              controller: _titleController,
              decoration: InputDecoration(
                filled: true,
                fillColor:
                    isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: mainColor, width: 1.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Enter task title',
                hintStyle: GoogleFonts.montserrat(
                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey,
                  fontSize: contentFontSize,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: width * 0.04,
                  vertical: height * 0.017,
                ),
              ),
            ),
            SizedBox(height: largeVerticalSpacing),
            Text(
              "Description",
              style: GoogleFonts.montserrat(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: labelFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: verticalSpacing * 0.5),
            TextField(
              style: GoogleFonts.montserrat(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: contentFontSize,
              ),
              controller: _contentController,
              maxLines: isLandscape ? 3 : 5,
              decoration: InputDecoration(
                filled: true,
                fillColor:
                    isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: mainColor, width: 1.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Enter task description',
                hintStyle: GoogleFonts.montserrat(
                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey,
                  fontSize: contentFontSize,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: width * 0.04,
                  vertical: height * 0.017,
                ),
              ),
            ),
            SizedBox(height: largeVerticalSpacing),
            Container(
              decoration: BoxDecoration(
                color:
                    isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade300),
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
                          checkColor: isDarkMode ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          side: BorderSide(
                            width: 1.5,
                            color: _isCompleted
                                ? completedTask
                                : (isDarkMode
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400),
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
                          color: theme.textTheme.bodyLarge?.color,
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Add Task',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.iconTheme.color,
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
