import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app_solulab/core/supaBase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Current user provider
final authUserProvider = StreamProvider<User?>((ref) {
  return SupabaseClientHelper.supabase.auth.onAuthStateChange
      .map((event) => event.session?.user);
});

// User metadata provider
final userMetadataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = SupabaseClientHelper.supabase.auth.currentUser;
  if (user == null) return {};

  try {
    final userData = await SupabaseClientHelper.supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    return userData ?? {};
  } catch (e) {
    return {};
  }
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

    // Listen directly to Supabase auth changes
    SupabaseClientHelper.supabase.auth.onAuthStateChange.listen((event) {
      final user = event.session?.user;
      print("Direct auth state change: user = $user");
      if (user != null) {
        state = AuthState.authenticated;
      } else {
        state = AuthState.unauthenticated;
      }
    });
  }

  void _initializeAuthState() {
    final currentUser = SupabaseClientHelper.supabase.auth.currentUser;
    // Set initial state based on current user
    if (currentUser != null) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  // Manual method to force auth state update
  void updateAuthState() {
    final currentUser = SupabaseClientHelper.supabase.auth.currentUser;
    if (currentUser != null) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
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

    // Force auth state update
    _ref.read(authStateProvider.notifier).updateAuthState();

    return response;
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    // The authStateProvider will handle clearing via the listener
  }

  // Update user metadata
  Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Check if user exists in the users table
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        // Create new user record with metadata
        await _supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          ...metadata,
        });
      } else {
        // Update existing user metadata
        await _supabase.from('users').update(metadata).eq('id', user.id);
      }
    } catch (e) {
      print("Error updating user metadata: $e");
      rethrow;
    }
  }

  // Get user metadata
  Future<Map<String, dynamic>> getUserMetadata() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};

    try {
      final userData =
          await _supabase.from('users').select().eq('id', user.id).single();

      return userData;
    } catch (e) {
      print("Error getting user metadata: $e");
      return {};
    }
  }
}
