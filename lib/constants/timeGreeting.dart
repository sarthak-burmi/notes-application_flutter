import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:todo_flutter_app/functions/auth_provider.dart';

class TimeGreetingScreen extends ConsumerWidget {
  const TimeGreetingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authUserProvider).value;
    final hour = DateTime.now().hour;
    String greeting = _getGreeting(hour);
    String emoji = _getEmoji(hour);
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('MMMM d, yyyy').format(now);
    String weekday = DateFormat('EEEE').format(now);

    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      greeting,
                      style: GoogleFonts.montserrat(
                        color: textTheme.displayLarge?.color,
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    emoji,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      "$formattedDate, $weekday",
                      style: GoogleFonts.montserrat(
                        color: textTheme.bodyMedium?.color,
                        fontSize: isSmallScreen ? 10 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // if (authUser != null && authUser.email != null)
              //   Text(
              //     authUser.email!,
              //     style: GoogleFonts.montserrat(
              //       color: textTheme.bodyMedium?.color,
              //       fontSize: 14,
              //     ),
              //     overflow: TextOverflow.ellipsis,
              //   ),
            ],
          ),
        ),
      ],
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getEmoji(int hour) {
    if (hour < 6) {
      return '🌙';
    } else if (hour < 12) {
      return '☀️';
    } else if (hour < 17) {
      return '🌤️';
    } else if (hour < 20) {
      return '🌇';
    } else {
      return '🌃';
    }
  }
}
