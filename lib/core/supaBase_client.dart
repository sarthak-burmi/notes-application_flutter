import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientHelper {
  static final supabase = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://uvloarykudepicfstzau.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2bG9hcnlrdWRlcGljZnN0emF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUwODgxODksImV4cCI6MjA2MDY2NDE4OX0.ZdWBVoIzj2EtgZ2_YE7NzTlPg_0Y2HGc0n_OzjuN4-8',
    );
  }

  static bool get isAuthenticated => supabase.auth.currentUser != null;

  static User? get currentUser => supabase.auth.currentUser;

  static String? get userId => currentUser?.id;
}
