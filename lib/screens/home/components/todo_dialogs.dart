import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todo_flutter_app/authentication/Login.dart';
import 'package:todo_flutter_app/core/supabase_client_sample.dart';
import 'package:todo_flutter_app/functions/auth_provider.dart';
import 'package:todo_flutter_app/functions/task_provider.dart';
import 'package:todo_flutter_app/main.dart';

class TodoDialogs {
  static void showLogoutConfirmation(
      BuildContext context, WidgetRef ref, bool isDarkMode) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor:
              isDarkMode ? theme.colorScheme.surface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 16 : 18,
                  color: theme.textTheme.displayLarge?.color,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to logout?',
                style: GoogleFonts.montserrat(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You will need to login again to access your tasks.',
                style: GoogleFonts.montserrat(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: isDarkMode ? Colors.grey.shade300 : Colors.black54,
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 20,
                  vertical: isSmallScreen ? 8 : 10,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _performLogout(context, ref, isDarkMode);
              },
              child: Text(
                'Logout',
                style: GoogleFonts.montserrat(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void showDeleteConfirmation(BuildContext context, WidgetRef ref,
      String todoId, bool isDarkMode, bool isSmallScreen) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              isDarkMode ? theme.colorScheme.surface : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Todo',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 16 : 18,
              color: theme.textTheme.displayLarge?.color,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this todo?',
            style: GoogleFonts.montserrat(
              fontSize: isSmallScreen ? 14 : 16,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: isDarkMode ? Colors.grey.shade300 : Colors.black54,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 8 : 10,
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
              onPressed: () {
                ref.read(todoProvider.notifier).deleteTodo(todoId);
                Navigator.of(context).pop();
                Fluttertoast.showToast(
                  msg: "Todo deleted successfully",
                  backgroundColor:
                      isDarkMode ? Colors.grey.shade800 : Colors.black87,
                );
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> _performLogout(
      BuildContext context, WidgetRef ref, bool isDarkMode) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(height: 16),
                Text(
                  'Logging out...',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      print("Starting logout process...");

      final currentUser = SupabaseClientHelper.supabase.auth.currentUser;
      print("Current user before logout: ${currentUser?.email}");

      await Future.any([
        ref.read(authControllerProvider).signOut(),
        Future.delayed(Duration(seconds: 15),
            () => throw TimeoutException('Logout timeout')),
      ]);

      print("Logout completed, clearing providers...");

      ref.invalidate(todoProvider);
      ref.invalidate(userMetadataProvider);
      ref.invalidate(authUserProvider);

      await Future.delayed(Duration(milliseconds: 1000));

      final userAfterLogout = SupabaseClientHelper.supabase.auth.currentUser;
      print("User after logout: $userAfterLogout");

      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }

      Fluttertoast.showToast(
        msg: "Logged out successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } on TimeoutException catch (e) {
      print("Logout timeout: $e");
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showLogoutErrorDialog(
          context,
          ref,
          "Logout timed out. Please check your connection and try again.",
          isDarkMode);
    } catch (e) {
      print("Logout error: $e");
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showLogoutErrorDialog(
          context, ref, "Error during logout: ${e.toString()}", isDarkMode);
    }
  }

  static void _showLogoutErrorDialog(BuildContext context, WidgetRef ref,
      String errorMessage, bool isDarkMode) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              isDarkMode ? theme.colorScheme.surface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(width: 8),
              Text(
                'Logout Error',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 16 : 18,
                  color: theme.textTheme.displayLarge?.color,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMessage,
                style: GoogleFonts.montserrat(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'You can try logging out again, or force logout to clear local data.',
                style: GoogleFonts.montserrat(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: isDarkMode ? Colors.grey.shade300 : Colors.black54,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout(context, ref, isDarkMode);
              },
              child: Text(
                'Retry',
                style: GoogleFonts.montserrat(
                  color: theme.colorScheme.primary,
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 8 : 10,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _forceLogout(context, ref, isDarkMode);
              },
              child: Text(
                'Force Logout',
                style: GoogleFonts.montserrat(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _forceLogout(
      BuildContext context, WidgetRef ref, bool isDarkMode) async {
    try {
      ref.invalidate(todoProvider);
      ref.invalidate(userMetadataProvider);
      ref.invalidate(authUserProvider);
      ref.invalidate(authStateProvider);

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }

      Fluttertoast.showToast(
        msg: "Force logout completed. Please login again.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      print("Force logout error: $e");

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
