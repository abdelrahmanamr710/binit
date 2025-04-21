import 'package:flutter/material.dart';

class BinOwnerSignUp extends StatefulWidget {
  const BinOwnerSignUp({super.key});

  @override
  BinOwnerSignUpState createState() => BinOwnerSignUpState();
}

class BinOwnerSignUpState extends State<BinOwnerSignUp> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: const Color(0xFFFFFFFF),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Image and Title
                Container(
                  height: 300, // Adjust as needed
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                          "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/4Az4G6YbU4/wf9rmns3_expires_30_days.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Text(
                        "Sign Up \nas \nBin Owner",
                        style: TextStyle(
                          color: const Color(0xFFFFFFFF),
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Input Fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _emailController,
                        hintText: "Your E-mail",
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _nameController,
                        hintText: "Name",
                        keyboardType: TextInputType.name,
                        prefixIcon: Icons.person,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _passwordController,
                        hintText: "Password",
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hintText: "Confirm Password",
                        obscureText: _obscureConfirmPassword,
                        prefixIcon: Icons.lock,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Register Button
                      ElevatedButton(
                        onPressed: () {
                          // Handle registration logic here
                          print("Email: ${_emailController.text}");
                          print("Name: ${_nameController.text}");
                          print("Password: ${_passwordController.text}");
                          print(
                              "Confirm Password: ${_confirmPasswordController.text}");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF184D47),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 45, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(
            color: const Color(0x40000000),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
          color: Color(0xFF777777),
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          border: InputBorder.none,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF777777)) : null,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}