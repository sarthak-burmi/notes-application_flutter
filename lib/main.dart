import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notes_app_solulab/autherntication/Login.dart';
import 'package:notes_app_solulab/provider/notes_provider.dart';
import 'package:provider/provider.dart'; // Import Provider package
import 'package:notes_app_solulab/screens/notes_list.dart';
import 'package:notes_app_solulab/screens/sign_in_screen.dart';
// Import your NoteProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => NoteProvider(FirebaseAuth.instance.currentUser!)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Note Taking App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return ChangeNotifierProvider(
            create: (_) => NoteProvider(snapshot.data!),
            child: NoteList(),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
