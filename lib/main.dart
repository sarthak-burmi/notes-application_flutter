import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app_solulab/autherntication/Login.dart';
import 'package:notes_app_solulab/core/supaBase_client.dart';
import 'package:notes_app_solulab/provider/auth_provider.dart';
import 'package:notes_app_solulab/screens/notes_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Note Taking App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Check initial auth state on load
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
        return const NoteList();
      case AuthState.unauthenticated:
      case AuthState.error:
        return const LoginScreen();
    }
  }
}
