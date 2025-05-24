import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todo_flutter_app/constants/colors.dart';

class TodoStatsCards extends StatelessWidget {
  final dynamic todoStats;
  final double horizontalPadding;
  final double width;
  final bool isSmallScreen;

  const TodoStatsCards({
    Key? key,
    required this.todoStats,
    required this.horizontalPadding,
    required this.width,
    required this.isSmallScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              'Total',
              todoStats.total.toString(),
              Icons.list_alt,
              Theme.of(context).colorScheme.primary,
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
}
