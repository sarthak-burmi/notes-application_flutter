import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app_solulab/core/supaBase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Current user provider
final authUserProvider = StreamProvider<User?>((ref) {
  return SupabaseClientHelper.supabase.auth.onAuthStateChange
      .map((event) => event.session?.user);
});

// Auth state provider - Converting to StateNotifierProvider for better state management
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref);
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthStateNotifier(this._ref) : super(AuthState.loading) {
    _initializeAuthState();
  }

  void _initializeAuthState() {
    final currentUser = SupabaseClientHelper.supabase.auth.currentUser;

    // Set initial state based on current user
    if (currentUser != null) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }

    // Listen for changes
    _ref.listen(authUserProvider, (previous, next) {
      next.when(
        data: (user) {
          print("Auth state changed in listener: user = $user");
          state = user != null
              ? AuthState.authenticated
              : AuthState.unauthenticated;
        },
        loading: () => state = AuthState.loading,
        error: (error, stack) {
          print("Auth error in listener: $error");
          state = AuthState.error;
        },
      );
    });
  }
}

// Auth controller
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

// States for authentication
enum AuthState {
  loading,
  authenticated,
  unauthenticated,
  error,
}

// Controller for authentication actions
class AuthController {
  final Ref _ref;
  final _supabase = SupabaseClientHelper.supabase;

  AuthController(this._ref);

  // Sign Up with Email and Password
  Future<AuthResponse> signUp(String email, String password) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    // Add debug print
    print("Sign up response: ${response.user}");

    return response;
  }

  // Sign In with Email and Password
  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    print("Sign in response: ${response.user}");

    return response;
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    // The authStateProvider will handle clearing via the listener
  }
}
