import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:todo_flutter_app/authentication/Login.dart';
import 'package:todo_flutter_app/constants/colors.dart';
import 'package:todo_flutter_app/constants/timeGreeting.dart';
import 'package:todo_flutter_app/core/supabase_client_sample.dart';
import 'package:todo_flutter_app/functions/auth_provider.dart';
import 'package:todo_flutter_app/functions/task_provider.dart';
import 'package:todo_flutter_app/main.dart';
import 'package:todo_flutter_app/model/TaskModel.dart';
import 'package:todo_flutter_app/screens/add_task.dart';
import 'package:todo_flutter_app/screens/task_edit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TodoListScreen extends ConsumerStatefulWidget {
  const TodoListScreen({super.key});

  @override
  ConsumerState<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends ConsumerState<TodoListScreen> {
  DateTime _selectedDate = DateTime.now();
  final List<DateTime> _dateList = [];
  TodoFilter _currentFilter = TodoFilter.all;
  TodoSort _currentSort = TodoSort.dueDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateDateList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _generateDateList() {
    final now = DateTime.now();
    _dateList.clear();
    _dateList.add(now);
    for (int i = 1; i <= 10; i++) {
      _dateList.add(now.add(Duration(days: i)));
    }
  }

  bool _isSelectedDate(Todo todo) {
    if (_currentFilter != TodoFilter.all) return true;

    try {
      final dueDate = DateTime.parse(todo.dueDate);
      return dueDate.year == _selectedDate.year &&
          dueDate.month == _selectedDate.month &&
          dueDate.day == _selectedDate.day;
    } catch (e) {
      return false;
    }
  }

  bool _isDateToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter & Sort',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: 20),

            // Filter options
            Text(
              'Filter by:',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TodoFilter.values.map((filter) {
                final isSelected = _currentFilter == filter;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentFilter = filter;
                      ref.read(todoProvider.notifier).setFilter(filter);
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? mainColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: mainColor),
                    ),
                    child: Text(
                      _getFilterLabel(filter),
                      style: GoogleFonts.montserrat(
                        color: isSelected ? Colors.white : mainColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 20),

            // Sort options
            Text(
              'Sort by:',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TodoSort.values.map((sort) {
                final isSelected = _currentSort == sort;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentSort = sort;
                      ref.read(todoProvider.notifier).setSort(sort);
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Text(
                      _getSortLabel(sort),
                      style: GoogleFonts.montserrat(
                        color: isSelected ? Colors.white : Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getFilterLabel(TodoFilter filter) {
    switch (filter) {
      case TodoFilter.all:
        return 'All';
      case TodoFilter.pending:
        return 'Pending';
      case TodoFilter.completed:
        return 'Completed';
      case TodoFilter.today:
        return 'Today';
      case TodoFilter.overdue:
        return 'Overdue';
      case TodoFilter.important:
        return 'Important';
    }
  }

  String _getSortLabel(TodoSort sort) {
    switch (sort) {
      case TodoSort.dueDate:
        return 'Due Date';
      case TodoSort.priority:
        return 'Priority';
      case TodoSort.created:
        return 'Created';
      case TodoSort.alphabetical:
        return 'A-Z';
    }
  }

  void _showLogoutConfirmationDialog(
      BuildContext context, WidgetRef ref, bool isDarkMode) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor:
              isDarkMode ? theme.colorScheme.surface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 16 : 18,
                  color: theme.textTheme.displayLarge?.color,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to logout?',
                style: GoogleFonts.montserrat(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You will need to login again to access your tasks.',
                style: GoogleFonts.montserrat(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: isDarkMode ? Colors.grey.shade300 : Colors.black54,
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 20,
                  vertical: isSmallScreen ? 8 : 10,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog first
                _performLogout(context, ref, isDarkMode); // Then perform logout
              },
              child: Text(
                'Logout',
                style: GoogleFonts.montserrat(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

// Add this robust logout method to your _NoteListState class
  Future<void> _performLogout(
      BuildContext context, WidgetRef ref, bool isDarkMode) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) {
        return PopScope(
          canPop: false, // Prevent back button during logout
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(height: 16),
                Text(
                  'Logging out...',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      print("Starting logout process...");

      // Get current user before logout for debugging
      final currentUser = SupabaseClientHelper.supabase.auth.currentUser;
      print("Current user before logout: ${currentUser?.email}");

      // Perform logout with timeout - using your AuthController
      await Future.any([
        ref.read(authControllerProvider).signOut(),
        Future.delayed(Duration(seconds: 15),
            () => throw TimeoutException('Logout timeout')),
      ]);

      print("Logout completed, clearing providers...");

      // Clear cached data after successful logout
      ref.invalidate(todoProvider);
      ref.invalidate(userMetadataProvider);
      ref.invalidate(authUserProvider);

      // Wait a bit for Supabase auth state to propagate
      await Future.delayed(Duration(milliseconds: 1000));

      // Verify logout was successful
      final userAfterLogout = SupabaseClientHelper.supabase.auth.currentUser;
      print("User after logout: $userAfterLogout");

      // Close loading dialog if still mounted
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Navigate to login screen and clear all routes
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }

      // Show success message
      Fluttertoast.showToast(
        msg: "Logged out successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } on TimeoutException catch (e) {
      print("Logout timeout: $e");
      // Handle timeout
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      _showLogoutErrorDialog(
          context,
          ref,
          "Logout timed out. Please check your connection and try again.",
          isDarkMode);
    } catch (e) {
      print("Logout error: $e");
      // Handle other errors
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show error dialog instead of just toast
      _showLogoutErrorDialog(
          context, ref, "Error during logout: ${e.toString()}", isDarkMode);
    }
  }

// Add this error dialog method to your _NoteListState class
  void _showLogoutErrorDialog(BuildContext context, WidgetRef ref,
      String errorMessage, bool isDarkMode) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              isDarkMode ? theme.colorScheme.surface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(width: 8),
              Text(
                'Logout Error',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 16 : 18,
                  color: theme.textTheme.displayLarge?.color,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMessage,
                style: GoogleFonts.montserrat(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'You can try logging out again, or force logout to clear local data.',
                style: GoogleFonts.montserrat(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: isDarkMode ? Colors.grey.shade300 : Colors.black54,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout(context, ref, isDarkMode); // Retry logout
              },
              child: Text(
                'Retry',
                style: GoogleFonts.montserrat(
                  color: theme.colorScheme.primary,
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 8 : 10,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _forceLogout(context, ref, isDarkMode);
              },
              child: Text(
                'Force Logout',
                style: GoogleFonts.montserrat(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

// Add this force logout method as a last resort
  Future<void> _forceLogout(
      BuildContext context, WidgetRef ref, bool isDarkMode) async {
    try {
      // Clear all providers and local state
      ref.invalidate(todoProvider);
      ref.invalidate(userMetadataProvider);
      ref.invalidate(authUserProvider);
      ref.invalidate(authStateProvider);

      // Force navigation to login screen
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }

      Fluttertoast.showToast(
        msg: "Force logout completed. Please login again.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      print("Force logout error: $e");

      // As absolute last resort, just navigate away
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final width = screenSize.width;
    final height = screenSize.height;
    final isSmallScreen = width < 360;
    final isMediumScreen = width >= 360 && width < 600;
    final horizontalPadding = isSmallScreen
        ? width * 0.03
        : (isMediumScreen ? width * 0.05 : width * 0.07);

    final authUser = ref.watch(authUserProvider).value;
    final todoState = ref.watch(todoProvider);
    final todoStats = ref.watch(todoStatsProvider);
    final userMetadata = ref.watch(userMetadataProvider).valueOrNull ?? {};

    // Get filtered todos
    List<Todo> displayTodos = todoState.filteredTodos;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      displayTodos = displayTodos
          .where((todo) =>
              todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              todo.content.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply date filter if using "All" filter
    if (_currentFilter == TodoFilter.all) {
      displayTodos =
          displayTodos.where((todo) => _isSelectedDate(todo)).toList();
    }

    if (authUser == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (todoState.isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                'Loading your todos...',
                style: GoogleFonts.montserrat(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: height * 0.02),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Todo Hub',
                          style: GoogleFonts.montserrat(
                            color: theme.textTheme.displayLarge?.color,
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userMetadata['name'] != null
                              ? 'Hello, ${userMetadata['name']}!'
                              : 'Hello!',
                          style: GoogleFonts.montserrat(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildThemeToggleButton(context, ref),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(isDarkMode ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => _showLogoutConfirmationDialog(
                          context, ref, isDarkMode),
                      icon: Icon(Icons.logout_rounded,
                          color: Colors.red, size: isSmallScreen ? 20 : 24),
                      constraints: BoxConstraints(
                        minWidth: isSmallScreen ? 32 : 48,
                        minHeight: isSmallScreen ? 32 : 48,
                      ),
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 12),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: height * 0.015),

            // Greeting
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: TimeGreetingScreen()),
                ],
              ),
            ),

            // Search Bar
            SizedBox(height: height * 0.02),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search todos...',
                  hintStyle: GoogleFonts.montserrat(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: GoogleFonts.montserrat(
                    color: theme.textTheme.bodyLarge?.color),
              ),
            ),

            // Statistics Cards
            SizedBox(height: height * 0.02),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total',
                      todoStats.total.toString(),
                      Icons.list_alt,
                      theme.colorScheme.primary,
                      isSmallScreen,
                    ),
                  ),
                  SizedBox(width: width * 0.02),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Pending',
                      todoStats.pending.toString(),
                      Icons.pending_actions,
                      Colors.orange,
                      isSmallScreen,
                    ),
                  ),
                  SizedBox(width: width * 0.02),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Completed',
                      todoStats.completed.toString(),
                      Icons.check_circle,
                      completedTask,
                      isSmallScreen,
                    ),
                  ),
                  SizedBox(width: width * 0.02),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Overdue',
                      todoStats.overdue.toString(),
                      Icons.warning,
                      Colors.red,
                      isSmallScreen,
                    ),
                  ),
                ],
              ),
            ),

            // Filter & Sort Bar
            SizedBox(height: height * 0.02),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1E1E1E)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, color: mainColor, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '${_getFilterLabel(_currentFilter)} • ${_getSortLabel(_currentSort)}',
                            style: GoogleFonts.montserrat(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showFilterBottomSheet(context),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: mainColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.tune, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Date selector (only show when filter is "All")
            if (_currentFilter == TodoFilter.all) ...[
              SizedBox(height: height * 0.02),
              Row(
                children: [
                  Expanded(
                    child: _buildDateSelector(isSmallScreen, theme, isDarkMode),
                  ),
                ],
              ),
            ],

            // Todo List
            Expanded(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalPadding * 0.8),
                child: _buildTodoList(context, ref, displayTodos,
                    todoState.isLoading, isSmallScreen),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _buildAddTodoButton(context, ref, authUser.id, isSmallScreen),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildThemeToggleButton(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    IconData themeIcon;
    if (themeMode == ThemeMode.light) {
      themeIcon = Icons.light_mode;
    } else if (themeMode == ThemeMode.dark) {
      themeIcon = Icons.dark_mode;
    } else {
      themeIcon = Icons.brightness_auto;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: () {
          if (themeMode == ThemeMode.light) {
            ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
          } else if (themeMode == ThemeMode.dark) {
            ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
          } else {
            ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
          }
        },
        icon: Icon(themeIcon,
            color: Theme.of(context).colorScheme.primary,
            size: MediaQuery.of(context).size.width < 360 ? 20 : 24),
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width < 360 ? 32 : 48,
          minHeight: MediaQuery.of(context).size.width < 360 ? 32 : 48,
        ),
        padding:
            EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 6 : 12),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color, bool isSmallScreen) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 8 : 12, horizontal: isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ??
            (isDarkMode ? theme.colorScheme.surface : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isSmallScreen ? 16 : 20),
          SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: theme.textTheme.displayLarge?.color,
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 14 : 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: GoogleFonts.montserrat(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: isSmallScreen ? 10 : 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(
      bool isSmallScreen, ThemeData theme, bool isDarkMode) {
    return Container(
      height: isSmallScreen ? 80 : 90,
      padding: const EdgeInsets.only(left: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _dateList.length,
        itemBuilder: (context, index) {
          final date = _dateList[index];
          final isToday = _isDateToday(date);
          final isSelected = _isSameDay(date, _selectedDate);

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: isSmallScreen ? (isToday ? 65 : 55) : (isToday ? 75 : 65),
              margin: EdgeInsets.only(right: 8, bottom: isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDarkMode
                        ? Colors.grey.shade800 // Dark mode fix
                        : (isToday
                            ? Colors.blue.shade50
                            : Colors.grey.shade50)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDarkMode
                          ? Colors.grey.shade600 // Dark mode border fix
                          : (isToday
                              ? Colors.blue.shade300
                              : Colors.grey.shade300)),
                  width: isToday ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday
                        ? 'Today'
                        : DateFormat('E').format(date).substring(0, 3),
                    style: GoogleFonts.montserrat(
                      color: isSelected
                          ? Colors.white
                          : (isDarkMode
                              ? Colors.grey.shade300 // Dark mode text fix
                              : (isToday
                                  ? Colors.blue.shade700
                                  : Colors.black)),
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      date.day.toString(),
                      style: GoogleFonts.montserrat(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDarkMode
                                ? Colors.grey.shade300 // Dark mode number fix
                                : (isToday
                                    ? Colors.blue.shade700
                                    : Colors.black)),
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodoItem(
      BuildContext context, WidgetRef ref, Todo todo, bool isSmallScreen) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    String formattedDueDate = "";
    try {
      final dueDate = DateTime.parse(todo.dueDate);
      formattedDueDate = DateFormat('dd/MM/yyyy').format(dueDate);
    } catch (e) {
      formattedDueDate = "Invalid date";
    }

    return AnimationConfiguration.staggeredList(
      position: 0,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Padding(
            padding: EdgeInsets.only(bottom: isSmallScreen ? 8.0 : 12.0),
            child: Slidable(
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) =>
                        _confirmDelete(context, ref, todo.id),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Delete',
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(16)),
                  ),
                  SlidableAction(
                    onPressed: (context) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TodoEdit(todo: todo)));
                    },
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Edit',
                  ),
                ],
              ),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: todo.isCompleted
                    ? (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50)
                    : (isDarkMode ? theme.colorScheme.surface : Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    width: 2,
                    color: todo.isOverdue && !todo.isCompleted
                        ? Colors.red
                        : todo.priority.color.withOpacity(0.5),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TodoEdit(todo: todo)));
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 12 : 16,
                      horizontal: isSmallScreen ? 12 : 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          children: [
                            // Priority indicator
                            Container(
                              width: 4,
                              height: 40,
                              decoration: BoxDecoration(
                                color: todo.priority.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 12),

                            // Checkbox
                            Transform.scale(
                              scale: isSmallScreen ? 0.9 : 1.1,
                              child: Checkbox(
                                value: todo.isCompleted,
                                activeColor: completedTask,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                                side: BorderSide(
                                  width: 1.5,
                                  color: todo.isCompleted
                                      ? completedTask
                                      : Colors.grey.shade400,
                                ),
                                onChanged: (bool? value) {
                                  ref
                                      .read(todoProvider.notifier)
                                      .toggleTodoCompletion(todo);
                                },
                              ),
                            ),
                            SizedBox(width: 8),

                            // Title and category
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          todo.title,
                                          style: GoogleFonts.montserrat(
                                            color: todo.isCompleted
                                                ? Colors.grey
                                                : theme.textTheme.displayLarge
                                                    ?.color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmallScreen ? 16 : 18,
                                            decoration: todo.isCompleted
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      // Category chip
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: todo.category.color
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              todo.category.icon,
                                              size: 12,
                                              color: todo.category.color,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              todo.category.label,
                                              style: GoogleFonts.montserrat(
                                                fontSize: 10,
                                                color: todo.category.color,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Important star
                            if (todo.isImportant)
                              GestureDetector(
                                onTap: () => ref
                                    .read(todoProvider.notifier)
                                    .toggleImportant(todo),
                                child: Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                  size: isSmallScreen ? 20 : 24,
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () => ref
                                    .read(todoProvider.notifier)
                                    .toggleImportant(todo),
                                child: Icon(
                                  Icons.star_border,
                                  color: Colors.grey,
                                  size: isSmallScreen ? 20 : 24,
                                ),
                              ),
                          ],
                        ),

                        SizedBox(height: 8),

                        // Description
                        if (todo.content.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(left: 60),
                            child: Text(
                              todo.content,
                              style: GoogleFonts.montserrat(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: todo.isCompleted
                                    ? Colors.grey
                                    : theme.textTheme.bodyLarge?.color,
                                decoration: todo.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                        SizedBox(height: 12),

                        // Footer with due date, time, and priority
                        Padding(
                          padding: EdgeInsets.only(left: 60),
                          child: Row(
                            children: [
                              // Due date
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: isSmallScreen ? 12 : 14,
                                    color: todo.isOverdue && !todo.isCompleted
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    todo.dueDateFormatted,
                                    style: GoogleFonts.montserrat(
                                      fontSize: isSmallScreen ? 10 : 12,
                                      color: todo.isOverdue && !todo.isCompleted
                                          ? Colors.red
                                          : Colors.grey,
                                      fontWeight:
                                          todo.isOverdue && !todo.isCompleted
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),

                              // Due time if available
                              if (todo.dueTime != null) ...[
                                SizedBox(width: 12),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: isSmallScreen ? 12 : 14,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      todo.dueTime!,
                                      style: GoogleFonts.montserrat(
                                        fontSize: isSmallScreen ? 10 : 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              Spacer(),

                              // Priority chip
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: todo.priority.color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  todo.priority.label,
                                  style: GoogleFonts.montserrat(
                                    fontSize: isSmallScreen ? 9 : 10,
                                    color: todo.priority.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String todoId) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              isDarkMode ? theme.colorScheme.surface : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Todo',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 16 : 18,
              color: theme.textTheme.displayLarge?.color,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this todo?',
            style: GoogleFonts.montserrat(
              fontSize: isSmallScreen ? 14 : 16,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: isDarkMode ? Colors.grey.shade300 : Colors.black54,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 8 : 10,
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
              onPressed: () {
                ref.read(todoProvider.notifier).deleteTodo(todoId);
                Navigator.of(context).pop();
                Fluttertoast.showToast(
                  msg: "Todo deleted successfully",
                  backgroundColor:
                      isDarkMode ? Colors.grey.shade800 : Colors.black87,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddTodoButton(
      BuildContext context, WidgetRef ref, String userId, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [mainColor, Color(0xFF8F6FE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      width: isSmallScreen ? 46 : 56,
      height: isSmallScreen ? 46 : 56,
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddTodoScreen()),
        ),
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: isSmallScreen ? 24 : 28,
        ),
      ),
    );
  }

  Widget _buildTodoList(BuildContext context, WidgetRef ref, List<Todo> todos,
      bool isLoading, bool isSmallScreen) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: mainColor),
      );
    }

    if (todos.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/Oops! 404 Error with a broken robot-rafiki.png",
                height: isSmallScreen ? 150 : 200,
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No todos match your search'
                    : (_currentFilter == TodoFilter.all
                        ? 'No todos for this day'
                        : 'No ${_getFilterLabel(_currentFilter).toLowerCase()} todos'),
                style: GoogleFonts.montserrat(
                  color: theme.textTheme.displayLarge?.color,
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                'Tap the + button to create a new todo',
                style: GoogleFonts.montserrat(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: isSmallScreen ? 12 : 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: todos.length,
        itemBuilder: (context, index) {
          final todo = todos[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildTodoItem(context, ref, todo, isSmallScreen),
              ),
            ),
          );
        },
      ),
    );
  }
}
