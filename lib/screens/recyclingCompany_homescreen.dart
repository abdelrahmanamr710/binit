import 'package:flutter/material.dart';

class RecyclingCompanyHomeScreen extends StatelessWidget {
  final String userName;
  const RecyclingCompanyHomeScreen({super.key, required this.userName});

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Recycling Company Home')),
    body: Center(
      child: Text('Welcome company, $userName!'),
    ),
  );
}
}