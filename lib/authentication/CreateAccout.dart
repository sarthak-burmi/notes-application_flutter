import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todo_flutter_app/authentication/Login.dart';
import 'package:todo_flutter_app/constants/colors.dart';
import 'package:todo_flutter_app/functions/auth_provider.dart';
import 'package:todo_flutter_app/screens/home/task_list.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Name, email and password cannot be empty';
          _isLoading = false;
        });
        return;
      }

      if (password.length < 6) {
        setState(() {
          _errorMessage = 'Password must be at least 6 characters';
          _isLoading = false;
        });
        return;
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        setState(() {
          _errorMessage = 'Please enter a valid email address';
          _isLoading = false;
        });
        return;
      }

      final authResponse =
          await ref.read(authControllerProvider).signUp(email, password);

      if (authResponse.user != null) {
        await ref.read(authControllerProvider).updateUserMetadata({
          'name': name,
        });
      }

      await ref.read(authControllerProvider).signIn(email, password);

      ref.read(authStateProvider.notifier).updateAuthState();

      ref.invalidate(userMetadataProvider);

      Fluttertoast.showToast(
        msg: "Account Created Successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const TodoListScreen()),
          (route) => false, // This removes all previous routes from the stack
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      Fluttertoast.showToast(
        msg: "Registration failed: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    double horizontalPadding = screenWidth * 0.06;
    double verticalSpacing = screenHeight * 0.02;

    double responsiveTextScale = mediaQuery.textScaleFactor;

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: verticalSpacing),
                          // Back button
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? colorScheme.surface
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: Theme.of(context).iconTheme.color,
                                size: 20,
                              ),
                            ),
                          ),
                          SizedBox(height: verticalSpacing),
                          // Header
                          Text(
                            "Create Account",
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 22 * responsiveTextScale,
                              color: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.color,
                            ),
                          ),
                          SizedBox(height: verticalSpacing / 2),
                          // Welcome text
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Get Started with\n',
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32 * responsiveTextScale,
                                      color: Theme.of(context)
                                          .textTheme
                                          .displayLarge
                                          ?.color,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Notes App',
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32 * responsiveTextScale,
                                      color: mainColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: verticalSpacing),
                          // Image - using ColorFiltered to adjust image for dark mode
                          Center(
                            child: Hero(
                              tag: 'auth_image',
                              child: Image.asset(
                                "assets/images/Prototyping process-pana (1).png",
                                height: screenHeight * 0.22,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(height: verticalSpacing),
                          // Error message
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red
                                    .withOpacity(isDarkMode ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.red
                                        .withOpacity(isDarkMode ? 0.4 : 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.montserrat(
                                        color: Colors.red,
                                        fontSize: 14 * responsiveTextScale,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_errorMessage != null)
                            SizedBox(height: verticalSpacing),

                          // Name field
                          _buildInputField(
                            label: "Name",
                            controller: _nameController,
                            hintText: 'Enter your name',
                            icon: Icons.person_outline,
                            keyboardType: TextInputType.name,
                            textScale: responsiveTextScale,
                            isDarkMode: isDarkMode,
                          ),
                          SizedBox(height: verticalSpacing),

                          // Email field
                          _buildInputField(
                            label: "Email",
                            controller: _emailController,
                            hintText: 'Enter your email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textScale: responsiveTextScale,
                            isDarkMode: isDarkMode,
                          ),
                          SizedBox(height: verticalSpacing),

                          // Password field
                          _buildPasswordField(
                            textScale: responsiveTextScale,
                            isDarkMode: isDarkMode,
                          ),

                          // Password requirements hint
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              'Password must be at least 6 characters',
                              style: GoogleFonts.montserrat(
                                fontSize: 12 * responsiveTextScale,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            ),
                          ),
                          SizedBox(height: verticalSpacing),

                          // Create account button
                          _buildCreateAccountButton(
                            textScale: responsiveTextScale,
                          ),
                          SizedBox(height: verticalSpacing / 2),

                          // Login option
                          _buildLoginOption(
                            textScale: responsiveTextScale,
                          ),
                          SizedBox(height: verticalSpacing / 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Extracted method for input fields
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required TextInputType keyboardType,
    required double textScale,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 14 * textScale,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.montserrat(
            fontSize: 15 * textScale,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.montserrat(
              fontSize: 14 * textScale,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            filled: true,
            // Use theme's fillColor
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            prefixIcon: Icon(icon, color: mainColor),
            // Use theme's border styling
            enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
            focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }

  // Extracted method for password field
  Widget _buildPasswordField({
    required double textScale,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Password",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 14 * textScale,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.montserrat(
            fontSize: 15 * textScale,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: GoogleFonts.montserrat(
              fontSize: 14 * textScale,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            prefixIcon: const Icon(Icons.lock_outline, color: mainColor),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            // Use theme's border styling
            enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
            focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }

  // Extracted method for create account button
  Widget _buildCreateAccountButton({
    required double textScale,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _isLoading ? null : _createAccount,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Create Account",
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 16 * textScale,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }

  // Extracted method for login option
  Widget _buildLoginOption({
    required double textScale,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          "Already have an account?",
          style: GoogleFonts.montserrat(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14 * textScale,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const LoginScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(-1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);
                  return SlideTransition(
                      position: offsetAnimation, child: child);
                },
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            "Login",
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 14 * textScale,
              color: mainColor,
            ),
          ),
        ),
      ],
    );
  }
}
