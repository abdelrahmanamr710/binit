import 'package:flutter/material.dart';
import 'package:binit/services/auth_service.dart'; // Import AuthService
import 'package:binit/models/user_model.dart';
import 'package:binit/screens/home_screen.dart'; // Import HomeScreen

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
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(user: user),
            ),
          );
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
      fontSize: 24, //  size
      fontWeight: FontWeight.bold, //  weight
      color: Colors.black, //  color.
    );
    const TextStyle labelTextStyle = TextStyle(
      fontSize: 16, //  size
      color: Colors.grey, //  color.
    );
    const OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(15)), // From Figma
      borderSide: BorderSide(color: Colors.grey), // Added border color
    );
    const TextStyle forgotPasswordTextStyle = TextStyle(
      color: Colors.blue, // From existing code
      fontSize: 14,
    );
    final ButtonStyle loginButtonStyle = ElevatedButton.styleFrom(
      backgroundColor:
      Colors.green, //  color.  Use your theme or a constant.
      foregroundColor: Colors.white, //  color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // From Figma
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
    const TextStyle signUpTextStyle = TextStyle(
      color: Colors.blue, // From existing code.
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    const TextStyle errorTextStyle = TextStyle(
      color: Colors.red,
      fontSize: 14,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Logo Section
              /*
              Image.asset(  // Replace with your actual logo asset path
                'assets/logo.png',
                height: 100,
              ),
              const SizedBox(height: 32),
              */
              Text(
                'Login',
                style: titleTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Email Input
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: labelTextStyle,
                  border: inputBorder,
                  focusedBorder: inputBorder,
                  enabledBorder: inputBorder,
                  prefixIcon: Icon(Icons.email, color: Colors.grey), // Added color
                  filled: true,
                  fillColor: Colors.white, // added background color
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
                  prefixIcon: Icon(Icons.lock, color: Colors.grey), // Added color
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
                    //  Forgot password functionality
                    print("Forgot Password Clicked");
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: forgotPasswordTextStyle,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: loginButtonStyle,
                child: _isLoading
                    ? const CircularProgressIndicator(
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : const Text('Sign In'),
              ),
              const SizedBox(height: 16),
              // Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Don't have an account?"),
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
              //show error message.
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _errorMessage,
                    style: errorTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

