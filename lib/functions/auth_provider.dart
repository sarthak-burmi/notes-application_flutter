import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_flutter_app/core/supaBase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authUserProvider = StreamProvider<User?>((ref) {
  return SupabaseClientHelper.supabase.auth.onAuthStateChange
      .map((event) => event.session?.user);
});

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

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref);
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  AuthStateNotifier(this._ref) : super(AuthState.loading) {
    _initializeAuthState();

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
    if (currentUser != null) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  void updateAuthState() {
    final currentUser = SupabaseClientHelper.supabase.auth.currentUser;
    if (currentUser != null) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

enum AuthState {
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthController {
  final Ref _ref;
  final _supabase = SupabaseClientHelper.supabase;
  AuthController(this._ref);

  Future<AuthResponse> signUp(String email, String password) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    print("Sign up response: ${response.user}");
    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    print("Sign in response: ${response.user}");

    _ref.read(authStateProvider.notifier).updateAuthState();

    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _ref.read(authStateProvider.notifier).updateAuthState();
  }

  Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        await _supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          ...metadata,
        });
      } else {
        await _supabase.from('users').update(metadata).eq('id', user.id);
      }
    } catch (e) {
      print("Error updating user metadata: $e");
      rethrow;
    }
  }

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
