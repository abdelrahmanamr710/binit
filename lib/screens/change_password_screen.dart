import 'package:flutter/material.dart';
import 'package:binit/services/auth_service.dart'; // Import AuthService.  Make sure this path is correct.
import 'package:binit/models/user_model.dart'; // Import UserModel.  Make sure this path is correct.


class ChangePasswordScreen extends StatefulWidget {
  final UserModel user;
  const ChangePasswordScreen({super.key, required this.user});

@override
_ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _changePassword() async {
    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text.trim() !=
          _confirmNewPasswordController.text.trim()) {
        setState(() {
          _errorMessage = 'New passwords do not match.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New passwords do not match.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      try {
        // Call the changePassword method in AuthService
        await _authService.changePassword(
          email: widget.user.email!, // Pass the user's email
          oldPassword: _oldPasswordController.text.trim(),
          newPassword: _newPasswordController.text.trim(),
        );

        // Provide feedback to the user.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully. Please sign in again.')),
        );
        // Navigate to the login screen or home screen after successful password change.
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false); //Go to Login
        //Navigator.of(context).pushReplacement(
        //  MaterialPageRoute(builder: (context) => HomeScreen(user: widget.user)), //or go to home
        //);

      } catch (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change password: $_errorMessage')),
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
    // Figma Styles
    const Color backgroundColor = Colors.white;
    const double screenPadding = 24.0;
    const TextStyle titleTextStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
    const TextStyle labelTextStyle = TextStyle(
      fontSize: 16,
      color: Colors.grey,
    );
    const OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(15)),
      borderSide: BorderSide(color: Colors.grey),
    );
    const TextStyle errorTextStyle = TextStyle(
      color: Colors.red,
      fontSize: 14,
    );
    final ButtonStyle changePasswordButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(screenPadding),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                //  Logo
                Image.asset(
                  'assets/logo/logo.png', //  path
                  fit: BoxFit.contain,
                  height: 100,
                ),
                const SizedBox(height: 30),
                Text(
                  'Change Password',
                  style: titleTextStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Old Password Input
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Old Password',
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
                      return 'Please enter your old password.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // New Password Input
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
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
                      return 'Please enter your new password.';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters long.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Confirm New Password Input
                TextFormField(
                  controller: _confirmNewPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
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
                      return 'Please confirm your new password.';
                    }
                    if (value != _newPasswordController.text.trim()) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: changePasswordButtonStyle,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : const Text('Change Password'),
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
    );
  }
}

