import 'package:flutter/material.dart';

class SignupAsScreen extends StatelessWidget {
  const SignupAsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // set background color
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Sign Up As',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48.0),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/bin_owner_signup');
              },
              style: Theme.of(context).elevatedButtonTheme.style,
              child: const Text('Bin Owner'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/recycling_company_signup');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                textStyle: const TextStyle(
                    fontSize: 18.0, fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 24.0),
              ),
              child: const Text('Recycling Company'),
            ),
          ],
        ),
      ),
    );
  }
}

