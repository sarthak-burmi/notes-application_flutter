import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimeGreetingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    int hour = now.hour;
    const morningStart = 0;
    const morningEnd = 12;
    const afternoonStart = 12;
    const afternoonEnd = 18;
    const eveningStart = 18;
    const eveningEnd = 21;
    const nightStart = 21;
    const nightEnd = 24;

    String greeting = '';

    if (hour >= morningStart && hour < morningEnd) {
      greeting = 'Good Morning';
    } else if (hour >= afternoonStart && hour < afternoonEnd) {
      greeting = 'Good Afternoon';
    } else if (hour >= eveningStart && hour < eveningEnd) {
      greeting = 'Good Evening';
    } else if (hour >= nightStart && hour < nightEnd) {
      greeting = 'Good Night';
    }
    return Text(
      greeting,
      style: GoogleFonts.montserrat(
        fontSize: 18,
      ),
    );
  }
}
