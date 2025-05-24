import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todo_flutter_app/constants/colors.dart';
import 'package:todo_flutter_app/constants/timeGreeting.dart';
import 'package:todo_flutter_app/functions/auth_provider.dart';
import 'package:todo_flutter_app/functions/task_provider.dart';
import 'package:todo_flutter_app/model/TaskModel.dart';
import 'package:todo_flutter_app/screens/add_task.dart';
import 'components/todo_header.dart';
import 'components/todo_search_bar.dart';
import 'components/todo_stats_cards.dart';
import 'components/todo_filter_bar.dart';
import 'components/todo_date_selector.dart';
import 'components/todo_list_widget.dart';
import 'components/todo_dialogs.dart';

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

  void _onFilterChanged(TodoFilter filter) {
    setState(() {
      _currentFilter = filter;
      ref.read(todoProvider.notifier).setFilter(filter);
    });
  }

  void _onSortChanged(TodoSort sort) {
    setState(() {
      _currentSort = sort;
      ref.read(todoProvider.notifier).setSort(sort);
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _onDateSelected(DateTime date) {
    setState(() => _selectedDate = date);
  }

  List<Todo> _getFilteredTodos() {
    final todoState = ref.watch(todoProvider);
    List<Todo> displayTodos = todoState.filteredTodos;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      displayTodos = displayTodos
          .where((todo) =>
              todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              todo.content.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_currentFilter == TodoFilter.all) {
      displayTodos =
          displayTodos.where((todo) => _isSelectedDate(todo)).toList();
    }

    return displayTodos;
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

    final displayTodos = _getFilteredTodos();

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

            // Header Component
            TodoHeader(
              userMetadata: userMetadata,
              horizontalPadding: horizontalPadding,
              isSmallScreen: isSmallScreen,
              onLogoutPressed: () => TodoDialogs.showLogoutConfirmation(
                context,
                ref,
                isDarkMode,
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

            SizedBox(height: height * 0.02),
            TodoSearchBar(
              controller: _searchController,
              horizontalPadding: horizontalPadding,
              searchQuery: _searchQuery,
              onSearchChanged: _onSearchChanged,
              isDarkMode: isDarkMode,
            ),

            SizedBox(height: height * 0.02),
            TodoStatsCards(
              todoStats: todoStats,
              horizontalPadding: horizontalPadding,
              width: width,
              isSmallScreen: isSmallScreen,
            ),

            SizedBox(height: height * 0.02),
            TodoFilterBar(
              currentFilter: _currentFilter,
              currentSort: _currentSort,
              horizontalPadding: horizontalPadding,
              isDarkMode: isDarkMode,
              getFilterLabel: _getFilterLabel,
              getSortLabel: _getSortLabel,
              onFilterSortPressed: () => _showFilterBottomSheet(context),
            ),

            if (_currentFilter == TodoFilter.all) ...[
              SizedBox(height: height * 0.02),
              Row(
                children: [
                  Expanded(
                    child: TodoDateSelector(
                      dateList: _dateList,
                      selectedDate: _selectedDate,
                      onDateSelected: _onDateSelected,
                      isSmallScreen: isSmallScreen,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ],
              ),
            ],

            Expanded(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalPadding * 0.8),
                child: TodoListWidget(
                  todos: displayTodos,
                  isLoading: todoState.isLoading,
                  isSmallScreen: isSmallScreen,
                  searchQuery: _searchQuery,
                  currentFilter: _currentFilter,
                  getFilterLabel: _getFilterLabel,
                ),
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
                    _onFilterChanged(filter);
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
                    _onSortChanged(sort);
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
}
