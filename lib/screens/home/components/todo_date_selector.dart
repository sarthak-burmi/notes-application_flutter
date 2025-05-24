import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TodoDateSelector extends StatelessWidget {
  final List<DateTime> dateList;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final bool isSmallScreen;
  final bool isDarkMode;

  const TodoDateSelector({
    Key? key,
    required this.dateList,
    required this.selectedDate,
    required this.onDateSelected,
    required this.isSmallScreen,
    required this.isDarkMode,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: isSmallScreen ? 80 : 90,
      padding: const EdgeInsets.only(left: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dateList.length,
        itemBuilder: (context, index) {
          final date = dateList[index];
          final isToday = _isDateToday(date);
          final isSelected = _isSameDay(date, selectedDate);

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: isSmallScreen ? (isToday ? 65 : 55) : (isToday ? 75 : 65),
              margin: EdgeInsets.only(right: 8, bottom: isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDarkMode
                        ? Colors.grey.shade800
                        : (isToday
                            ? Colors.blue.shade50
                            : Colors.grey.shade50)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDarkMode
                          ? Colors.grey.shade600
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
                              ? Colors.grey.shade300
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
                                ? Colors.grey.shade300
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
}
