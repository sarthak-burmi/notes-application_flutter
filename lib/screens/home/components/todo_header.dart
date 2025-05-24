import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todo_flutter_app/main.dart';

class TodoHeader extends ConsumerWidget {
  final Map<String, dynamic> userMetadata;
  final double horizontalPadding;
  final bool isSmallScreen;
  final VoidCallback onLogoutPressed;

  const TodoHeader({
    Key? key,
    required this.userMetadata,
    required this.horizontalPadding,
    required this.isSmallScreen,
    required this.onLogoutPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Todo Hub',
                  style: GoogleFonts.montserrat(
                    color: theme.textTheme.displayLarge?.color,
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userMetadata['name'] != null
                      ? 'Hello, ${userMetadata['name']}!'
                      : 'Hello!',
                  style: GoogleFonts.montserrat(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildThemeToggleButton(context, ref),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(isDarkMode ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: onLogoutPressed,
              icon: Icon(Icons.logout_rounded,
                  color: Colors.red, size: isSmallScreen ? 20 : 24),
              constraints: BoxConstraints(
                minWidth: isSmallScreen ? 32 : 48,
                minHeight: isSmallScreen ? 32 : 48,
              ),
              padding: EdgeInsets.all(isSmallScreen ? 6 : 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggleButton(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    IconData themeIcon;
    if (themeMode == ThemeMode.light) {
      themeIcon = Icons.light_mode;
    } else if (themeMode == ThemeMode.dark) {
      themeIcon = Icons.dark_mode;
    } else {
      themeIcon = Icons.brightness_auto;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: () {
          if (themeMode == ThemeMode.light) {
            ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
          } else if (themeMode == ThemeMode.dark) {
            ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
          } else {
            ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
          }
        },
        icon: Icon(themeIcon,
            color: Theme.of(context).colorScheme.primary,
            size: isSmallScreen ? 20 : 24),
        constraints: BoxConstraints(
          minWidth: isSmallScreen ? 32 : 48,
          minHeight: isSmallScreen ? 32 : 48,
        ),
        padding: EdgeInsets.all(isSmallScreen ? 6 : 12),
      ),
    );
  }
}
