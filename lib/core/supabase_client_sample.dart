import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientHelper {
  static final supabase = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: '........ YOUR DATABASE URL ........',
      anonKey: '........ YOUR ANON KEY ........',
    );
  }

  static bool get isAuthenticated => supabase.auth.currentUser != null;

  static User? get currentUser => supabase.auth.currentUser;

  static String? get userId => currentUser?.id;
}
