import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:todo_flutter_app/constants/colors.dart';
import 'package:todo_flutter_app/model/TaskModel.dart'; // Import for Todo
import 'package:todo_flutter_app/functions/task_provider.dart'; // Import for TodoFilter
import 'todo_item.dart';

class TodoListWidget extends ConsumerWidget {
  final List<Todo> todos; // ✅ Specific type
  final bool isLoading;
  final bool isSmallScreen;
  final String searchQuery;
  final TodoFilter currentFilter; // ✅ Specific type
  final String Function(TodoFilter) getFilterLabel; // ✅ Specific type

  const TodoListWidget({
    Key? key,
    required this.todos,
    required this.isLoading,
    required this.isSmallScreen,
    required this.searchQuery,
    required this.currentFilter,
    required this.getFilterLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                searchQuery.isNotEmpty
                    ? 'No todos match your search'
                    : (currentFilter == TodoFilter.all
                        ? 'No todos for this day'
                        : 'No ${getFilterLabel(currentFilter).toLowerCase()} todos'),
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
                child: TodoItem(todo: todo, isSmallScreen: isSmallScreen),
              ),
            ),
          );
        },
      ),
    );
  }
}
