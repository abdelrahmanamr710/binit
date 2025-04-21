import 'package:flutter/material.dart';

class BinOwnerHomeScreen extends StatelessWidget {
  final String userName;
  const BinOwnerHomeScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bin Owner Home')),
      body: Center(
        child: Text('Welcome, $userName!'),
      ),
    );
  }
}
