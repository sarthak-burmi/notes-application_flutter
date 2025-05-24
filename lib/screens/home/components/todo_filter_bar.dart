import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todo_flutter_app/constants/colors.dart';
import 'package:todo_flutter_app/functions/task_provider.dart'; // Import for TodoFilter and TodoSort

class TodoFilterBar extends StatelessWidget {
  final TodoFilter currentFilter; // ✅ Specific type
  final TodoSort currentSort; // ✅ Specific type
  final double horizontalPadding;
  final bool isDarkMode;
  final String Function(TodoFilter) getFilterLabel; // ✅ Specific type
  final String Function(TodoSort) getSortLabel; // ✅ Specific type
  final VoidCallback onFilterSortPressed;

  const TodoFilterBar({
    Key? key,
    required this.currentFilter,
    required this.currentSort,
    required this.horizontalPadding,
    required this.isDarkMode,
    required this.getFilterLabel,
    required this.getSortLabel,
    required this.onFilterSortPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  Icon(Icons.filter_list, color: mainColor, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '${getFilterLabel(currentFilter)} • ${getSortLabel(currentSort)}',
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
            onTap: onFilterSortPressed,
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
    );
  }
}
