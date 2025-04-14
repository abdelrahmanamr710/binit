import 'package:flutter/material.dart';
import 'package:binit/models/user_model.dart';

class HomeScreen extends StatelessWidget {
  final UserModel? user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Use user.userType to determine which home screen to show
    if (user?.userType == 'binOwner') {
      return BinOwnerHomeScreen(userName: user?.name ?? 'Bin Owner');
    } else if (user?.userType == 'recyclingCompany') {
      return RecyclingCompanyHomeScreen(userName: user?.name ?? 'Recycling Company');
    } else {
      //show error
      return const Center(child: Text('Error: Invalid user type'));
    }
  }
}

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

class RecyclingCompanyHomeScreen extends StatelessWidget {
  final String userName;
  const RecyclingCompanyHomeScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recycling Company Home')),
      body: Center(
        child: Text('Welcome, $userName!'),
      ),
    );
  }
}

