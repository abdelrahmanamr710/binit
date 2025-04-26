import 'package:flutter/material.dart';
import 'package:binit/services/auth_service.dart';
import 'package:binit/models/user_model.dart';
import 'package:binit/screens/binOwner_homescreen.dart';

class BinOwnerSignupScreen extends StatefulWidget {
  const BinOwnerSignupScreen({super.key});

  @override
  _BinOwnerSignupScreenState createState() => _BinOwnerSignupScreenState();
}

class _BinOwnerSignupScreenState extends State<BinOwnerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text.trim() !=
          _confirmPasswordController.text.trim()) {
        setState(() {
          _errorMessage = 'Passwords do not match.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final UserModel? user = await _authService.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          userType: 'binOwner',
        );

        if (user != null) {
          // Use pushAndRemoveUntil to prevent going back to the signup screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => BinOwnerHomeScreen(userName: user.name ?? "", user: user),
            ),
                (route) => false, // Remove all previous routes
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to sign up.')),
          );
        }
      } catch (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $_errorMessage')),
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
    const Color backgroundColor = Colors.white;
    const double screenPadding = 24.0;

    const TextStyle titleTextStyle = TextStyle(
      fontSize: 60,
      fontWeight: FontWeight.w400,
      color: Colors.white,
      fontFamily: 'Roboto Flex',
    );

    const TextStyle labelTextStyle = TextStyle(
      fontSize: 15,
      color: Color(0xFF777777),
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w700,
    );

    const OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(15)),
      borderSide: BorderSide(color: Colors.grey),
    );

    const TextStyle errorTextStyle = TextStyle(color: Colors.red, fontSize: 14);

    final ButtonStyle registerButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF184D47),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      textStyle: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        fontFamily: 'Roboto',
      ),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/png/rightcornergreen.png"),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(screenPadding),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Logo
                    Image.asset(
                      'assets/png/rightcornergreen.png',
                      fit: BoxFit.contain,
                      height: 100,
                    ),
                    const SizedBox(height: 30),

                    // Title
                    const Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: Text(
                        'Sign Up as Bin Owner',
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          fontFamily: 'Roboto Flex',
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        labelStyle: labelTextStyle,
                        border: inputBorder,
                        focusedBorder: inputBorder,
                        enabledBorder: inputBorder,
                        prefixIcon: Icon(Icons.person, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
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
                          return 'Please enter your email address.';
                        }
                        final emailRegex = RegExp(
                            r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
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
                          return 'Please enter your password.';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters long.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
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
                          return 'Please confirm your password.';
                        }
                        if (value != _passwordController.text.trim()) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    _isLoading
                        ? const CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                        : ElevatedButton(
                      onPressed: _signUp,
                      style: registerButtonStyle,
                      child: const Text('Register'),
                    ),
                    const SizedBox(height: 16),

                    if (_errorMessage.isNotEmpty)
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
          ),
        ),
      ),
    );
  }
}

