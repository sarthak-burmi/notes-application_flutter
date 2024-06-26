import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app_solulab/autherntication/Login.dart';
import 'package:notes_app_solulab/constants/colors.dart';
import 'package:notes_app_solulab/screens/notes_list.dart';
import 'package:notes_app_solulab/screens/sign_in_screen.dart';

class CreatAccountScreen extends StatefulWidget {
  const CreatAccountScreen({super.key});

  @override
  State<CreatAccountScreen> createState() => _CreatAccountScreen();
}

class _CreatAccountScreen extends State<CreatAccountScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  Future<void> _creataccount() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      Fluttertoast.showToast(
        msg: "Account Created\n Login with your account",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Navigate to NotesList screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NoteList()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        print('Invalid email address format.');
      } else {
        print('Error: ${e.message}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 50, 26, 0),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const Image(
                  //   image: AssetImage("assets/images/Login-rafiki.png"),
                  //   width: 600,
                  //   height: 350,
                  // ),
                  Text(
                    "Create Account",
                    style: GoogleFonts.kanit(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                      ),
                      children: [
                        TextSpan(
                          text: 'Get Started with\n',
                          style: GoogleFonts.kanit(
                            fontWeight: FontWeight.bold,
                            fontSize: 40,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: 'Notes',
                          style: GoogleFonts.kanit(
                            fontWeight: FontWeight.bold,
                            fontSize: 40,
                            color: mainColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    "assets/images/Prototyping process-pana (1).png",
                    height: height * 0.40,
                  ),
                  const SizedBox(height: 30),
                  makeInput(label: 'Email', controller: _emailController),
                  const SizedBox(height: 10),
                  makeInput(
                      label: 'Password',
                      controller: _passwordController,
                      obscureText: true),

                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 350,
                        height: 55,
                        padding: const EdgeInsets.only(top: 3, left: 3),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            border: const Border(
                              bottom: BorderSide(color: Colors.black),
                              top: BorderSide(color: Colors.black),
                              left: BorderSide(color: Colors.black),
                              right: BorderSide(color: Colors.black),
                            )),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          onPressed: () {
                            _creataccount();
                          },
                          child: Text(
                            "Create Account",
                            style: GoogleFonts.kanit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text("Have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => LoginScreen()));
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: mainColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget makeInput({label, obscureText = false, controller}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const SizedBox(
        height: 5,
      ),
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Colors.black,
            ),
          ),
          focusColor: mainColor,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: mainColor,
              width: 2,
            ),
          ),
        ),
      ),
      const SizedBox(
        height: 10,
      ),
    ],
  );
}
