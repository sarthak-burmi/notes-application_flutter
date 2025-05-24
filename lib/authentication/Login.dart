import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todo_flutter_app/authentication/CreateAccout.dart';
import 'package:todo_flutter_app/constants/colors.dart';
import 'package:todo_flutter_app/functions/auth_provider.dart';
import 'package:todo_flutter_app/screens/home/task_list.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Email and password cannot be empty';
          _isLoading = false;
        });
        return;
      }

      // Perform login and store response
      final response =
          await ref.read(authControllerProvider).signIn(email, password);

      // Debug prints to track state changes
      print("Login successful: ${response.user?.email}");
      print("Session active: ${response.session != null}");

      // IMPORTANT: Force auth state update
      ref.read(authStateProvider.notifier).updateAuthState();

      // Refresh user metadata
      ref.invalidate(userMetadataProvider);

      // Check current auth state after login
      final authState = ref.read(authStateProvider);
      print("Current auth state after login update: $authState");

      Fluttertoast.showToast(
        msg: "Login successful",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Force explicit navigation to NoteList
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const TodoListScreen()),
          (route) => false, // This removes all previous routes from the stack
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme and responsive measurements
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height;
    final width = mediaQuery.size.width;
    final isSmallScreen = width < 360;
    final horizontalPadding = width * 0.06;

    // Adjust text scaling for better responsiveness
    final textScaleFactor = mediaQuery.textScaleFactor.clamp(0.8, 1.2);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          // Responsive spacing calculation
          final imageHeight = constraints.maxHeight * 0.25;
          final verticalSpacing = constraints.maxHeight * 0.02;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: verticalSpacing * 2),
                      // Header
                      Text(
                        "Login To Your Account",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 18 : 22,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      SizedBox(height: verticalSpacing),
                      // Welcome text
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            children: [
                              TextSpan(
                                text: 'Welcome',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 28 : 32,
                                  color: mainColor,
                                ),
                              ),
                              TextSpan(
                                text: ' Back',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 28 : 32,
                                  color: theme.textTheme.titleLarge?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: verticalSpacing),
                      // Image - responsive sizing
                      Center(
                        child: Hero(
                          tag: 'auth_image',
                          child: Image.asset(
                            "assets/images/Login-rafiki (1).png",
                            height: imageHeight,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: verticalSpacing),
                      // Error message
                      if (_errorMessage != null)
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                          decoration: BoxDecoration(
                            color: deleteColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: deleteColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: deleteColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.montserrat(
                                    color: deleteColor,
                                    fontSize: 14 * textScaleFactor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_errorMessage != null)
                        SizedBox(height: verticalSpacing),
                      // Input fields
                      Text(
                        "Email",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 14 * textScaleFactor,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.montserrat(
                          fontSize: 15 * textScaleFactor,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: GoogleFonts.montserrat(
                            fontSize: 14 * textScaleFactor,
                            color:
                                isDarkMode ? Colors.grey.shade500 : Colors.grey,
                          ),
                          filled: true,
                          fillColor: isDarkMode
                              ? const Color(0xFF1E1E1E)
                              : Colors.grey.shade50,
                          prefixIcon:
                              Icon(Icons.email_outlined, color: mainColor),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                                width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: mainColor, width: 1.5),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12 : 16,
                            horizontal: isSmallScreen ? 12 : 16,
                          ),
                        ),
                      ),
                      SizedBox(height: verticalSpacing),
                      Text(
                        "Password",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 14 * textScaleFactor,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.montserrat(
                          fontSize: 15 * textScaleFactor,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: GoogleFonts.montserrat(
                            fontSize: 14 * textScaleFactor,
                            color:
                                isDarkMode ? Colors.grey.shade500 : Colors.grey,
                          ),
                          filled: true,
                          fillColor: isDarkMode
                              ? const Color(0xFF1E1E1E)
                              : Colors.grey.shade50,
                          prefixIcon:
                              Icon(Icons.lock_outline, color: mainColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: isDarkMode
                                  ? Colors.grey.shade500
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                                width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: mainColor, width: 1.5),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12 : 16,
                            horizontal: isSmallScreen ? 12 : 16,
                          ),
                        ),
                      ),
                      SizedBox(height: verticalSpacing * 1.5),
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 48 : 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 10 : 14,
                            ),
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? SizedBox(
                                  width: isSmallScreen ? 20 : 24,
                                  height: isSmallScreen ? 20 : 24,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Login",
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen
                                            ? 14 * textScaleFactor
                                            : 16 * textScaleFactor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.arrow_forward,
                                        size: isSmallScreen ? 16 : 18),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: verticalSpacing),
                      // Sign up option
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            Text(
                              "Don't have an account?",
                              style: GoogleFonts.montserrat(
                                color: isDarkMode
                                    ? Colors.white54
                                    : Colors.black54,
                                fontSize: 14 * textScaleFactor,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        const CreateAccountScreen(),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOut;
                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));
                                      var offsetAnimation =
                                          animation.drive(tween);
                                      return SlideTransition(
                                          position: offsetAnimation,
                                          child: child);
                                    },
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: Text(
                                "Register",
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14 * textScaleFactor,
                                  color: mainColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: verticalSpacing),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
