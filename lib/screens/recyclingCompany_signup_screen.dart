import 'package:flutter/material.dart';
import 'package:binit/services/auth_service.dart'; // Import AuthService
import 'package:binit/models/user_model.dart';
import 'package:binit/screens/recyclingCompany_homescreen.dart'; // Import the home screen

class RecyclingCompanySignupScreen extends StatefulWidget {
  const RecyclingCompanySignupScreen({super.key});

  @override
  _RecyclingCompanySignupScreenState createState() =>
      _RecyclingCompanySignupScreenState();
}

class _RecyclingCompanySignupScreenState
    extends State<RecyclingCompanySignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _taxIdController = TextEditingController(); // Added tax ID controller
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    _taxIdController.dispose(); // Dispose tax ID controller
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
        // Pass the phone and taxId to the signUpWithEmailAndPassword method.
        final UserModel? user = await _authService.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _companyNameController.text.trim(),
          userType: 'recyclingCompany',
          phone: _phoneController.text.trim(),
          taxId: _taxIdController.text.trim(), // Include tax ID in the user data
        );
        if (user != null) {
          // Navigate to the recycling company home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RecyclingCompanyHomeScreen(), // Pass the user data, handle null with ""
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $_errorMessage')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Figma Styles
    const Color backgroundColor = Colors.white;
    const double screenPadding = 24.0;
    const TextStyle titleTextStyle = TextStyle(
      fontSize: 50, // Adjusted title size
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
                    // Removed Logo
                    //const SizedBox(height: 0), // Adjusted spacing

                    // Title
                    const SizedBox(height: 60),
                    const Padding(
                      padding: EdgeInsets.only(right: 0.01, left: 50.0),
                      child: Text(
                        'Sign Up as Recycling Company',  // Add a line break with \n
                        style: TextStyle(
                          fontFamily: 'Roboto',  // Replace 'Roboto' with your desired font family
                          fontSize: 45,          // Adjust the font size as needed
                          // fontWeight: FontWeight.bold, // Adjust the font weight if necessary
                          color: Colors.white,  // Set text color to white
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),

// Add this SizedBox to create space under the text
                    const SizedBox(height: 30),  // Adjust the height as needed


                    // Company Name Input
                    TextFormField(
                      controller: _companyNameController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                        labelStyle: labelTextStyle,
                        border: inputBorder,
                        focusedBorder: inputBorder,
                        enabledBorder: inputBorder,
                        prefixIcon: Icon(Icons.business, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your company name.';
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
                        final emailRegex = RegExp(
                          r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[\w-]{2,4}$',
                        );
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
                    const SizedBox(height: 16),
                    // Phone Number Input
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: labelTextStyle,
                        border: inputBorder,
                        focusedBorder: inputBorder,
                        enabledBorder: inputBorder,
                        prefixIcon: Icon(Icons.phone, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number.';
                        }
                        //  phone number validation
                        if (value.length < 10) {
                          return 'Please enter a valid phone number.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Tax ID Input
                    TextFormField(
                      controller: _taxIdController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Tax ID / Registration Number',
                        labelStyle: labelTextStyle,
                        border: inputBorder,
                        focusedBorder: inputBorder,
                        enabledBorder: inputBorder,
                        prefixIcon: Icon(Icons.badge, color: Colors.grey),
                        // Example icon
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your Tax ID / Registration Number';
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