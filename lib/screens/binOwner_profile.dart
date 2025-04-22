import 'package:flutter/material.dart';
import 'package:binit/services/auth_service.dart'; // Import AuthService.  Make sure this path is correct.
import 'package:binit/models/user_model.dart'; // Import UserModel.  Make sure this path is correct.
import 'package:binit/screens/change_password_screen.dart'; // Import ChangePasswordScreen. Make sure this path is correct.


class BinOwnerProfile extends StatefulWidget {
  final UserModel user;
  const BinOwnerProfile({super.key, required this.user});

@override
_BinOwnerProfileState createState() => _BinOwnerProfileState();
}

class _BinOwnerProfileState extends State<BinOwnerProfile> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isEditing = false; // Track editing state
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Initialize the text controllers with the user's current values.
    _emailController.text = widget.user.email ?? '';
    _nameController.text = widget.user.name ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      try {
        // Update user data.
        UserModel updatedUser = UserModel(
          uid: widget.user.uid, // Keep the original UID
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          userType: widget.user.userType, // Keep the user type
        );

        await _authService.updateUserProfile(updatedUser); //  updateUserProfile method in AuthService

        // Provide feedback to the user.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
        _toggleEditing(); // Exit editing mode after successful update.

      } catch (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $_errorMessage')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    // Figma Styles (as close as possible without complete Figma code)
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
    final ButtonStyle editButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
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
    final ButtonStyle saveButtonStyle = ElevatedButton.styleFrom(
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
    final ButtonStyle changePasswordButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
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
        title: const Text('Profile'),
        actions: [
          if (!_isEditing) // Show Edit button when not editing
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEditing,
            ),
        ],
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
                  height: 100, // added height
                ),
                const SizedBox(height: 30),
                Text(
                  'Bin Owner Profile',
                  style: titleTextStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
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
                  enabled: _isEditing, // Enable editing only when _isEditing is true
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
                  enabled: _isEditing, // Enable editing only when _isEditing is true
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChangePasswordScreen(user: widget.user),
                      ),
                    );
                  },
                  style: changePasswordButtonStyle,
                  child: const Text('Change Password'),
                ),
                const SizedBox(height: 24),
                if (_isEditing) // Show Save and Cancel buttons only when editing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: saveButtonStyle,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : const Text('Save'),
                      ),
                      ElevatedButton(
                        onPressed: _toggleEditing,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: const Text('Cancel'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

