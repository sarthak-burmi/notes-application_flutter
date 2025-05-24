import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todo_flutter_app/constants/colors.dart';
import 'package:todo_flutter_app/functions/task_provider.dart';
import 'package:todo_flutter_app/model/TaskModel.dart'; // Import for Todo
import 'package:todo_flutter_app/screens/task_edit.dart';
import 'todo_dialogs.dart';

class TodoItem extends ConsumerWidget {
  final Todo todo; // ✅ Specific type instead of dynamic
  final bool isSmallScreen;

  const TodoItem({
    Key? key,
    required this.todo,
    required this.isSmallScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 8.0 : 12.0),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => TodoDialogs.showDeleteConfirmation(
                context,
                ref,
                todo.id,
                isDarkMode,
                isSmallScreen,
              ),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(16)),
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
                                          : theme.textTheme.displayLarge?.color,
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
                                    color: todo.category.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
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
                                fontWeight: todo.isOverdue && !todo.isCompleted
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
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    );
  }
}
