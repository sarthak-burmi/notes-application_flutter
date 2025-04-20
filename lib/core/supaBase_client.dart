import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientHelper {
  // Get the singleton instance of Supabase client
  static final supabase = Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url:
          'https://uvloarykudepicfstzau.supabase.co', // Replace with your Supabase URL
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2bG9hcnlrdWRlcGljZnN0emF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUwODgxODksImV4cCI6MjA2MDY2NDE4OX0.ZdWBVoIzj2EtgZ2_YE7NzTlPg_0Y2HGc0n_OzjuN4-8', // Replace with your Supabase anon key
    );
  }

  // Check if user is logged in
  static bool get isAuthenticated => supabase.auth.currentUser != null;

  // Get current user
  static User? get currentUser => supabase.auth.currentUser;

  // Get user id
  static String? get userId => currentUser?.id;
}
