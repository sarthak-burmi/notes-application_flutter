import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TodoSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final double horizontalPadding;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final bool isDarkMode;

  const TodoSearchBar({
    Key? key,
    required this.controller,
    required this.horizontalPadding,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: TextField(
        controller: controller,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search todos...',
          hintStyle: GoogleFonts.montserrat(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    controller.clear();
                    onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: GoogleFonts.montserrat(color: theme.textTheme.bodyLarge?.color),
      ),
    );
  }
}
