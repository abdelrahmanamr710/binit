import 'package:flutter/material.dart';
import 'package:binit/services/auth_service.dart'; // Import AuthService
import 'package:binit/models/user_model.dart'; // Import UserModel
import 'package:binit/screens/binOwner_homescreen.dart'; // Import the BinOwnerHomeScreen

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
  //final _addressController = TextEditingController(); // Removed address controller
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    //_addressController.dispose(); // Removed address controller
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
        // Pass the address to the signUpWithEmailAndPassword method.
        final UserModel? user = await _authService.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          userType: 'binOwner',
          //address: _addressController.text.trim(), // Removed address from user data
        );
        if (user != null) {
          // Navigate to the BinOwnerHomeScreen after successful signup
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  BinOwnerHomeScreen(), // Pass the user name
            ),
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
                      'assets/png/rightcornergreen.png', // path
                      fit: BoxFit.contain,
                      height: 160, // added height
                    ),
                    const SizedBox(height: 30),
                    const Padding(
                      padding: EdgeInsets.only(right: 0.01, left: 50.0),
                      child: Text(
                        'Sign Up as Bin Owner',  // Add a line break with \n
                        style: TextStyle(
                          fontFamily: 'Roboto',  // Replace 'Roboto' with your desired font family
                          fontSize: 55,          // Adjust the font size as needed
                          // fontWeight: FontWeight.bold, // Adjust the font weight if necessary
                          color: Colors.white,  // Set text color to white
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(height: 30),  // Adjust the height as needed


                    // Name Input
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
                        prefixIcon: Icon(Icons.email, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address.';
                        }
                        final emailRegex =
                        RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email address.';
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
                          return 'Please enter your password.';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters long.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Confirm Password Input
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

