import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_flutter_app/authentication/Login.dart';
import 'package:todo_flutter_app/constants/appTheme.dart';
import 'package:todo_flutter_app/core/supaBase_client.dart';
import 'package:todo_flutter_app/functions/auth_provider.dart';
import 'package:todo_flutter_app/screens/home/task_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('themeMode') ?? 0;
    state = ThemeMode.values[themeModeIndex];
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemeMode(state);
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _saveThemeMode(state);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseClientHelper.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaskHub',

      // Theme configuration
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeMode,

      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  ConsumerState createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = SupabaseClientHelper.supabase.auth.currentUser;
      print("AuthGate init - Current user: $currentUser");
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the auth state to ensure it updates when auth changes
    final authState = ref.watch(authStateProvider);

    // Add debug information
    print("Current auth state in AuthGate: $authState");

    switch (authState) {
      case AuthState.loading:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Loading authentication state..."),
              ],
            ),
          ),
        );
      case AuthState.authenticated:
        return const TodoListScreen();
      case AuthState.unauthenticated:
      case AuthState.error:
        return const LoginScreen();
    }
  }
}
