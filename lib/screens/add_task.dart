import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todo_flutter_app/constants/colors.dart';
import 'package:todo_flutter_app/functions/auth_provider.dart';
import 'package:todo_flutter_app/functions/task_provider.dart';
import 'package:todo_flutter_app/model/TaskModel.dart'; // Your Todo model

class AddTodoScreen extends ConsumerStatefulWidget {
  const AddTodoScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends ConsumerState<AddTodoScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isCompleted = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  TodoPriority _selectedPriority = TodoPriority.medium;
  TodoCategory _selectedCategory = TodoCategory.other;
  bool _isImportant = false;
  bool _isLoading = false;
  bool _contentOptional = true; // Make description optional for quick todos

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
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
      firstDate: DateTime.now().subtract(Duration(days: 1)),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveTodo() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Title cannot be empty', style: GoogleFonts.montserrat()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Content is optional for quick todos
    if (!_contentOptional && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Description cannot be empty',
              style: GoogleFonts.montserrat()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final userId = ref.read(authUserProvider).value?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You need to be logged in to add todos',
              style: GoogleFonts.montserrat()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? dueTimeString;
      if (_selectedTime != null) {
        dueTimeString =
            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      }

      final newTodo = Todo(
        id: '',
        title: title,
        content: content,
        ownerId: userId,
        isCompleted: _isCompleted,
        dueDate: _selectedDate.toIso8601String(),
        dueTime: dueTimeString,
        priority: _selectedPriority,
        category: _selectedCategory,
        isImportant: _isImportant,
      );

      await ref.read(todoProvider.notifier).addTodo(newTodo);

      if (mounted) {
        Fluttertoast.showToast(
          msg: "Todo added successfully",
          backgroundColor: Colors.green,
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
            content:
                Text('Error: ${e.toString()}', style: GoogleFonts.montserrat()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final width = size.width;
    final height = size.height;
    final isDarkMode = theme.brightness == Brightness.dark;

    final isSmallScreen = width < 360;
    final isTablet = width > 600;
    final horizontalPadding = width *
        (isSmallScreen
            ? 0.03
            : isTablet
                ? 0.08
                : 0.05);
    final verticalSpacing = height * 0.015;
    final largeVerticalSpacing = height * 0.025;

    final contentFontSize = isSmallScreen
        ? 14.0
        : isTablet
            ? 18.0
            : 16.0;
    final labelFontSize = isSmallScreen
        ? 14.0
        : isTablet
            ? 18.0
            : 16.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Add Todo',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: theme.iconTheme.color, size: isSmallScreen ? 18 : 24),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Quick mode toggle
          IconButton(
            icon: Icon(
              _contentOptional ? Icons.flash_on : Icons.flash_off,
              color: _contentOptional ? Colors.orange : theme.iconTheme.color,
            ),
            onPressed: () {
              setState(() {
                _contentOptional = !_contentOptional;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _contentOptional
                        ? 'Quick mode: Description optional'
                        : 'Normal mode: Description required',
                    style: GoogleFonts.montserrat(),
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: verticalSpacing),

                      // Title Input
                      _buildSectionTitle('Todo Title', labelFontSize, theme),
                      SizedBox(height: verticalSpacing * 0.5),
                      _buildTitleInput(contentFontSize, isDarkMode, theme),
                      SizedBox(height: largeVerticalSpacing),

                      // Description Input (Optional in quick mode)
                      _buildSectionTitle(
                        _contentOptional
                            ? 'Description (Optional)'
                            : 'Description',
                        labelFontSize,
                        theme,
                      ),
                      SizedBox(height: verticalSpacing * 0.5),
                      _buildDescriptionInput(
                          contentFontSize, isDarkMode, theme),
                      SizedBox(height: largeVerticalSpacing),

                      // Due Date & Time
                      _buildSectionTitle(
                          'Due Date & Time', labelFontSize, theme),
                      SizedBox(height: verticalSpacing * 0.5),
                      _buildDateTimeSelector(
                          contentFontSize, isDarkMode, theme, width),
                      SizedBox(height: largeVerticalSpacing),

                      // Priority Selection
                      _buildSectionTitle('Priority', labelFontSize, theme),
                      SizedBox(height: verticalSpacing * 0.5),
                      _buildPrioritySelector(
                          contentFontSize, isDarkMode, theme),
                      SizedBox(height: largeVerticalSpacing),

                      // Category Selection
                      _buildSectionTitle('Category', labelFontSize, theme),
                      SizedBox(height: verticalSpacing * 0.5),
                      _buildCategorySelector(
                          contentFontSize, isDarkMode, theme, isSmallScreen),
                      SizedBox(height: largeVerticalSpacing),

                      // Important & Completed toggles
                      _buildToggleOptions(
                          contentFontSize, isDarkMode, theme, width),
                      SizedBox(height: largeVerticalSpacing),

                      // Save Button
                      _buildSaveButton(theme, height, isSmallScreen),
                      SizedBox(height: largeVerticalSpacing),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, double fontSize, ThemeData theme) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        color: theme.textTheme.bodyLarge?.color,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTitleInput(double fontSize, bool isDarkMode, ThemeData theme) {
    return TextFormField(
      style: GoogleFonts.montserrat(
          color: theme.textTheme.bodyLarge?.color, fontSize: fontSize),
      controller: _titleController,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mainColor, width: 1.5),
        ),
        hintText: 'Enter todo title',
        hintStyle: GoogleFonts.montserrat(
          color: isDarkMode ? Colors.grey.shade500 : Colors.grey,
          fontSize: fontSize,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDescriptionInput(
      double fontSize, bool isDarkMode, ThemeData theme) {
    return TextField(
      style: GoogleFonts.montserrat(
          color: theme.textTheme.bodyLarge?.color, fontSize: fontSize),
      controller: _contentController,
      maxLines: 3,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mainColor, width: 1.5),
        ),
        hintText: _contentOptional
            ? 'Add details (optional)'
            : 'Enter todo description',
        hintStyle: GoogleFonts.montserrat(
          color: isDarkMode ? Colors.grey.shade500 : Colors.grey,
          fontSize: fontSize,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDateTimeSelector(
      double fontSize, bool isDarkMode, ThemeData theme, double width) {
    final formattedDate = DateFormat('MMM d, yyyy').format(_selectedDate);
    final formattedTime =
        _selectedTime != null ? _selectedTime!.format(context) : 'No time set';

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color:
                    isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: mainColor, size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      formattedDate,
                      style: GoogleFonts.montserrat(
                        fontSize: fontSize,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _selectTime(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color:
                    isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedTime != null
                      ? mainColor
                      : (isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: _selectedTime != null ? mainColor : Colors.grey,
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      formattedTime,
                      style: GoogleFonts.montserrat(
                        fontSize: fontSize * 0.85,
                        color: _selectedTime != null
                            ? theme.textTheme.bodyLarge?.color
                            : Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector(
      double fontSize, bool isDarkMode, ThemeData theme) {
    return Row(
      children: TodoPriority.values.map((priority) {
        final isSelected = _selectedPriority == priority;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPriority = priority),
            child: Container(
              margin: EdgeInsets.only(
                  right: priority != TodoPriority.values.last ? 8 : 0),
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? priority.color.withOpacity(0.2)
                    : (isDarkMode
                        ? const Color(0xFF1E1E1E)
                        : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? priority.color
                      : (isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade300),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                priority.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: fontSize * 0.9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? priority.color
                      : theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategorySelector(
      double fontSize, bool isDarkMode, ThemeData theme, bool isSmallScreen) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TodoCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? category.color.withOpacity(0.2)
                  : (isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.grey.shade50),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? category.color
                    : (isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade300),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category.icon,
                  size: isSmallScreen ? 16 : 18,
                  color: isSelected
                      ? category.color
                      : theme.textTheme.bodyLarge?.color,
                ),
                SizedBox(width: 4),
                Text(
                  category.label,
                  style: GoogleFonts.montserrat(
                    fontSize: fontSize * 0.85,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? category.color
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToggleOptions(
      double fontSize, bool isDarkMode, ThemeData theme, double width) {
    return Column(
      children: [
        // Important toggle
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _isImportant = !_isImportant),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    _isImportant ? Icons.star : Icons.star_border,
                    color: _isImportant ? Colors.orange : Colors.grey,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Mark as important',
                    style: GoogleFonts.montserrat(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        // Completed toggle
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _isCompleted = !_isCompleted),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Transform.scale(
                    scale: 1.1,
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
                  SizedBox(width: 12),
                  Text(
                    'Mark as completed',
                    style: GoogleFonts.montserrat(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_isCompleted) ...[
                    SizedBox(width: 8),
                    Icon(
                      Icons.check_circle_outline,
                      color: completedTask,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ThemeData theme, double height, bool isSmallScreen) {
    final buttonHeight = height * (isSmallScreen ? 0.055 : 0.06);
    final buttonFontSize = isSmallScreen ? 16.0 : 18.0;

    return SizedBox(
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
        onPressed: _isLoading ? null : _saveTodo,
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
                'Add Todo',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: buttonFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
