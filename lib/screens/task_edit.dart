import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todo_flutter_app/constants/colors.dart';
import 'package:todo_flutter_app/functions/task_provider.dart';
import 'package:todo_flutter_app/model/TaskModel.dart';

class TodoEdit extends ConsumerStatefulWidget {
  final Todo todo;

  const TodoEdit({Key? key, required this.todo}) : super(key: key);

  @override
  ConsumerState<TodoEdit> createState() => _TodoEditState();
}

class _TodoEditState extends ConsumerState<TodoEdit>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late bool _isCompleted;
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  late TodoPriority _selectedPriority;
  late TodoCategory _selectedCategory;
  late bool _isImportant;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _contentController = TextEditingController(text: widget.todo.content);
    _isCompleted = widget.todo.isCompleted;
    _selectedPriority = widget.todo.priority;
    _selectedCategory = widget.todo.category;
    _isImportant = widget.todo.isImportant;

    _selectedDate = DateTime.tryParse(widget.todo.dueDate) ?? DateTime.now();

    // Parse time if available
    if (widget.todo.dueTime != null) {
      try {
        final timeParts = widget.todo.dueTime!.split(':');
        _selectedTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      } catch (e) {
        _selectedTime = null;
      }
    }

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).brightness == Brightness.light
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
              style: TextButton.styleFrom(foregroundColor: mainColor),
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
          backgroundColor: deleteColor,
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

      final updatedTodo = widget.todo.copyWith(
        title: title,
        content: content,
        isCompleted: _isCompleted,
        dueDate: _selectedDate.toIso8601String(),
        dueTime: dueTimeString,
        priority: _selectedPriority,
        category: _selectedCategory,
        isImportant: _isImportant,
      );

      if (widget.todo.id.isEmpty) {
        await ref.read(todoProvider.notifier).addTodo(updatedTodo);
        if (mounted) {
          Fluttertoast.showToast(
            msg: "Todo added successfully",
            backgroundColor: Colors.green,
          );
        }
      } else {
        await ref.read(todoProvider.notifier).updateTodo(updatedTodo);
        if (mounted) {
          Fluttertoast.showToast(
            msg: "Todo updated successfully",
            backgroundColor: Colors.green,
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
            content:
                Text('Error: ${e.toString()}', style: GoogleFonts.montserrat()),
            backgroundColor: deleteColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final isSmallScreen = maxWidth < 360;
        final isTablet = maxWidth > 600;

        double horizontalPadding = isTablet ? maxWidth * 0.1 : maxWidth * 0.05;
        double verticalSpacing =
            maxHeight > 800 ? maxHeight * 0.02 : maxHeight * 0.015;
        double fontSize = isSmallScreen ? 14.0 : (isTablet ? 18.0 : 16.0);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            title: Text(
              widget.todo.id.isEmpty ? 'Add Todo' : 'Edit Todo',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
                fontSize: isSmallScreen ? 18 : 20,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: theme.iconTheme.color),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (widget.todo.id.isNotEmpty)
                IconButton(
                  onPressed: () => _confirmDelete(context),
                  icon: Icon(Icons.delete_outline_rounded, color: deleteColor),
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

                        // Hero Image
                        Center(
                          child: Hero(
                            tag: 'todo_image',
                            child: Image.asset(
                              "assets/images/add_notes-bro.png",
                              height: maxHeight * 0.2,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(height: verticalSpacing),

                        // Priority & Important Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildSectionTitle(
                                  'Priority', fontSize, theme),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _isImportant = !_isImportant),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _isImportant
                                      ? Colors.orange.withOpacity(0.2)
                                      : (isDarkMode
                                          ? const Color(0xFF1E1E1E)
                                          : Colors.grey.shade50),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _isImportant
                                        ? Colors.orange
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isImportant
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: _isImportant
                                          ? Colors.orange
                                          : Colors.grey,
                                      size: 18,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Important',
                                      style: GoogleFonts.montserrat(
                                        fontSize: fontSize * 0.85,
                                        color: _isImportant
                                            ? Colors.orange
                                            : Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: verticalSpacing * 0.5),
                        _buildPrioritySelector(fontSize, isDarkMode, theme),
                        SizedBox(height: verticalSpacing * 1.5),

                        // Category Selection
                        _buildSectionTitle('Category', fontSize, theme),
                        SizedBox(height: verticalSpacing * 0.5),
                        _buildCategorySelector(
                            fontSize, isDarkMode, theme, isSmallScreen),
                        SizedBox(height: verticalSpacing * 1.5),

                        // Title Input
                        _buildSectionTitle('Todo Title', fontSize, theme),
                        SizedBox(height: verticalSpacing * 0.5),
                        _buildTitleInput(fontSize, isDarkMode, theme),
                        SizedBox(height: verticalSpacing * 1.5),

                        // Description Input
                        _buildSectionTitle(
                            'Description (Optional)', fontSize, theme),
                        SizedBox(height: verticalSpacing * 0.5),
                        _buildDescriptionInput(fontSize, isDarkMode, theme),
                        SizedBox(height: verticalSpacing * 1.5),

                        // Due Date & Time
                        _buildSectionTitle('Due Date & Time', fontSize, theme),
                        SizedBox(height: verticalSpacing * 0.5),
                        _buildDateTimeSelector(
                            fontSize, isDarkMode, theme, maxWidth),
                        SizedBox(height: verticalSpacing * 1.5),

                        // Completed Toggle
                        _buildCompletedTaskToggle(fontSize, isDarkMode, theme),
                        SizedBox(height: verticalSpacing * 2),

                        // Save Button
                        _buildSaveButton(
                            theme, maxHeight, isSmallScreen, fontSize),
                        SizedBox(height: verticalSpacing),
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
          borderSide: const BorderSide(color: mainColor, width: 1.5),
        ),
        hintText: 'Enter todo title',
        hintStyle: GoogleFonts.montserrat(
          color: isDarkMode ? Colors.grey.shade500 : Colors.grey,
          fontSize: fontSize,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDescriptionInput(
      double fontSize, bool isDarkMode, ThemeData theme) {
    return TextField(
      style: GoogleFonts.montserrat(
          color: theme.textTheme.bodyLarge?.color, fontSize: fontSize),
      controller: _contentController,
      maxLines: 4,
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
          borderSide: const BorderSide(color: mainColor, width: 1.5),
        ),
        hintText: 'Add todo details (optional)',
        hintStyle: GoogleFonts.montserrat(
          color: isDarkMode ? Colors.grey.shade500 : Colors.grey,
          fontSize: fontSize,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDateTimeSelector(
      double fontSize, bool isDarkMode, ThemeData theme, double maxWidth) {
    final formattedDate = DateFormat('MMM d, yyyy').format(_selectedDate);
    final formattedTime =
        _selectedTime != null ? _selectedTime!.format(context) : 'No time set';

    return Column(
      children: [
        // Date Selector
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: mainColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  formattedDate,
                  style: GoogleFonts.montserrat(
                    fontSize: fontSize,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(5),
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
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 12),

        // Time Selector
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF1E1E1E)
                        : Colors.grey.shade50,
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
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formattedTime,
                        style: GoogleFonts.montserrat(
                          fontSize: fontSize,
                          color: _selectedTime != null
                              ? theme.textTheme.bodyLarge?.color
                              : Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedTime != null)
                        GestureDetector(
                          onTap: () => setState(() => _selectedTime = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.clear,
                              color: Colors.red,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedTaskToggle(
      double fontSize, bool isDarkMode, ThemeData theme) {
    return Container(
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: _isCompleted,
                  activeColor: completedTask,
                  checkColor: isDarkMode ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  side: BorderSide(
                    width: 1.5,
                    color: _isCompleted
                        ? completedTask
                        : (isDarkMode
                            ? Colors.grey.shade600
                            : Colors.grey.shade400),
                  ),
                  onChanged: (bool? value) =>
                      setState(() => _isCompleted = value ?? false),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Mark as completed',
                style: GoogleFonts.montserrat(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_isCompleted) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle_outline,
                    color: completedTask, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(
      ThemeData theme, double maxHeight, bool isSmallScreen, double fontSize) {
    final buttonHeight = maxHeight > 600 ? 60.0 : 50.0;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: mainColor,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isLoading ? null : _saveTodo,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                widget.todo.id.isEmpty ? 'Add Todo' : 'Save Changes',
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text(
                'Delete Todo',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this todo?',
                style: GoogleFonts.montserrat(
                    color: theme.textTheme.bodyLarge?.color),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone.',
                        style: GoogleFonts.montserrat(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              onPressed: () async {
                await ref
                    .read(todoProvider.notifier)
                    .deleteTodo(widget.todo.id);
                if (mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close edit screen
                  Fluttertoast.showToast(
                    msg: "Todo deleted successfully",
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
