// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class SignInScreen extends StatefulWidget {
//   @override
//   _SignInScreenState createState() => _SignInScreenState();
// }

// class _SignInScreenState extends State<SignInScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   Future<void> _signIn() async {
//     try {
//       await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text,
//       );
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'user-not-found') {
//         print('No user found for that email.');
//       } else if (e.code == 'wrong-password') {
//         print('Wrong password provided for that user.');
//       } else if (e.code == 'invalid-email') {
//         print('Invalid email address format.');
//       } else {
//         print('Error: ${e.message}');
//       }
//     } catch (e) {
//       print('Error: $e');
//     }
//   }

//   Future<void> _signUp() async {
//     try {
//       await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text,
//       );
//       // Navigate to next screen after successful sign-up
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'weak-password') {
//         print('The password provided is too weak.');
//       } else if (e.code == 'email-already-in-use') {
//         print('The account already exists for that email.');
//       } else if (e.code == 'invalid-email') {
//         print('Invalid email address format.');
//       } else {
//         print('Error: ${e.message}');
//       }
//     } catch (e) {
//       print('Error: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Sign In')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             TextField(
//               controller: _emailController,
//               decoration: InputDecoration(labelText: 'Email'),
//             ),
//             TextField(
//               controller: _passwordController,
//               decoration: InputDecoration(labelText: 'Password'),
//               obscureText: true,
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _signIn,
//               child: Text('Sign In'),
//             ),
//             ElevatedButton(
//               onPressed: _signUp,
//               child: Text('Sign Up'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
