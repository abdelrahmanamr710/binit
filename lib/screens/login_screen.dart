import 'package:flutter/material.dart';
import 'package:binit/services/auth_service.dart'; // Import AuthService
import 'package:binit/models/user_model.dart';
import 'package:binit/screens/binOwner_homescreen.dart'; // Import BinOwnerHomeScreen
import 'package:binit/screens/recyclingCompany_homescreen.dart'; // Import RecyclingCompanyHomeScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      try {
        final UserModel? user = await _authService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (user != null) {
          // Check user type and navigate accordingly
          if (user.userType == 'binOwner') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => BinOwnerHomeScreen(), // Pass the user object
              ),
            );
          } else if (user.userType == 'recyclingCompany') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => RecyclingCompanyHomeScreen(),
              ),
            );
          } else {
            // Handle unknown user type (optional - navigate to a default screen or show an error)
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(), //stay in login
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Unknown user type.'),
                  backgroundColor: Colors.red),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to retrieve user data.'),
                backgroundColor: Colors.red),
          );
        }
      } catch (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: $error'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Figma Styles (as close as possible without complete Figma code)
    const Color backgroundColor = Colors.white; // From Figma
    const double screenPadding = 24.0; //  padding
    const TextStyle titleTextStyle = TextStyle(
        fontSize: 60, //  size from figma
        fontWeight: FontWeight.w400, //  weight from figma
        color: Colors.white, //  color from figma.
        fontFamily: 'Roboto Flex'
    );
    const TextStyle labelTextStyle = TextStyle(
        fontSize: 15, //  size from figma
        color:  const Color(0xFF777777), //  color from figma.
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w700
    );
    const OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(15)), // From Figma
      borderSide: const BorderSide(color: Colors.grey), // Added border color
    );
    const TextStyle forgotPasswordTextStyle = TextStyle(
        color: Colors.black, // From  figma
        fontSize: 15,
        fontFamily: 'Futura Lt BT',
        fontWeight: FontWeight.w400,
        letterSpacing: -0.75
    );
    final ButtonStyle loginButtonStyle = ElevatedButton.styleFrom(
      backgroundColor:
      const Color(0xFF184D47), //  color from figma.
      foregroundColor: Colors.white, //  color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // From Figma
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      textStyle: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          fontFamily: 'Roboto'
      ),
    );
    const TextStyle signUpTextStyle = TextStyle(
      color:  const Color(0xFF141313), // From figma.
      fontWeight: FontWeight.w400,
      fontSize: 15,
      fontFamily: 'Roboto',
      decoration: TextDecoration.underline,
    );
    const TextStyle errorTextStyle = TextStyle(
      color: Colors.red,
      fontSize: 14,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            screenPadding,
            screenPadding,
            screenPadding,
            screenPadding,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    height: 200,  // Restored original fixed height
                    child: Image.asset(
                      'assets/logo/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 30),  // Restored original spacing
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: const Text(
                      'Login',
                      style: titleTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Email Input
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      labelStyle: labelTextStyle,
                      border: inputBorder,
                      focusedBorder: inputBorder,
                      enabledBorder: inputBorder,
                      prefixIcon: Icon(Icons.email, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      labelStyle: labelTextStyle,
                      border: inputBorder,
                      focusedBorder: inputBorder,
                      enabledBorder: inputBorder,
                      prefixIcon: Icon(Icons.lock, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        print("Forgot Password Clicked");
                      },
                      child: const Text(
                        'Forgot Your Password?',
                        style: forgotPasswordTextStyle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Login Button
                  SizedBox(
                    height: 60,  // Fixed height for button
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: loginButtonStyle,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text('Sign in'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text("Don't Have an Account? "),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/signup_as');
                        },
                        child: const Text(
                          'Sign Up',
                          style: signUpTextStyle,
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _errorMessage,
                        style: errorTextStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  // Add bottom padding to ensure content is above keyboard
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

