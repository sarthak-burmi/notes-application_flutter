import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:notes_app_solulab/provider/auth_provider.dart';

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

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.montserrat(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  emoji,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Colors.black54,
                ),
                const SizedBox(width: 4),
                Text(
                  "$formattedDate, $weekday",
                  style: GoogleFonts.montserrat(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // if (authUser != null && authUser.email != null)
            //   Text(
            //     authUser.email!,
            //     style: GoogleFonts.montserrat(
            //       color: Colors.black54,
            //       fontSize: 14,
            //     ),
            //     overflow: TextOverflow.ellipsis,
            //   ),
          ],
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
      return '🌙'; // Night
    } else if (hour < 12) {
      return '☀️'; // Morning
    } else if (hour < 17) {
      return '🌤️'; // Afternoon
    } else if (hour < 20) {
      return '🌇'; // Evening
    } else {
      return '🌃'; // Night
    }
  }
}
