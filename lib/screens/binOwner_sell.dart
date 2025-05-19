import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:binit/screens/sell_requested.dart';
import 'package:binit/models/user_model.dart'; // Import UserModel
import 'package:flutter/cupertino.dart'; // Import for CupertinoDatePicker if needed
import 'package:binit/screens/binOwner_stock.dart';
import 'package:binit/screens/binOwner_homescreen.dart';
import 'package:binit/screens/binOwner_profile.dart';

// Define a Cubit for managing the SellForm state
class SellFormCubit extends Cubit<Map<String, dynamic>> {
  SellFormCubit() : super({
    'kilograms': 0.0,
    'price': 0.0,
    'pickupDate': DateTime.now(),
  });

  void updateField(String field, dynamic value) {
    emit({...state, field: value});
  }

  // Function to submit the form data to Firebase
  Future<void> submitForm(BuildContext context) async {
    // Ensure Firebase is initialized
    await Firebase.initializeApp();
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Add the data to the 'sell_offers' collection
      await firestore.collection('sell_offers').add({
        'kilograms': state['kilograms'],
        'price': state['price'],
        'pickupDate': state['pickupDate'],
        'phoneNumber': state['phoneNumber'],
        'district': state['district'],
        'city': state['city'],
        'pickupAddress': state['pickupAddress'],
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'status': 'pending',
        'date': FieldValue.serverTimestamp(),
      });
      emit({
        'kilograms': 0.0,
        'price': 0.0,
        'pickupDate': DateTime.now(),
      });
      print('Form data submitted successfully!');

      // Navigate to SellDone screen after successful submission
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SellDone(userName: '', user: null), // Pass empty values
        ),
      );
    } catch (error) {
      print('Error submitting form: $error');
      throw error;
    }
  }
}

class BinOwnerSell extends StatelessWidget {
  final String userName;
  final UserModel? user;

  const BinOwnerSell({super.key, required this.userName, this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellFormCubit(),
      child: UserSellForm(userName: userName, user: user), // Pass the parameters
    );
  }
}

class UserSellForm extends StatefulWidget {
  final String userName;
  final UserModel? user;
  const UserSellForm({super.key, required this.userName, this.user});

  @override
  _UserSellFormState createState() => _UserSellFormState();
}

class _UserSellFormState extends State<UserSellForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _pickupAddressController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final SellFormCubit cubit = context.read<SellFormCubit>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: cubit.state['pickupDate'] ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null && picked != cubit.state['pickupDate']) {
      cubit.updateField('pickupDate', picked);
    }
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _pickupAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SellFormCubit cubit = context.watch<SellFormCubit>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A524F),
        title: const Text('Sell', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0), // Reduced padding
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Set Weight to be Sold:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0), // Reduced font size
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('0kg', style: TextStyle(fontSize: 14.0)), // Reduced font size
                  const Text('Max: 50kg',
                      style: TextStyle(fontSize: 10.0, color: Colors.grey)), // Reduced font size
                ],
              ),
              Slider(
                value: cubit.state['kilograms'] ?? 0.0,
                min: 0,
                max: 50,
                divisions: 50,
                label: '${(cubit.state['kilograms'] ?? 0.0).round()}kg',
                activeColor: const Color(0xFF26A69A),
                inactiveColor: Colors.grey[300],
                onChanged: (double newWeight) {
                  cubit.updateField('kilograms', newWeight);
                },
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(6.0), // Reduced padding
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.0), // Smaller radius
                    color: Colors.grey[200],
                  ),
                  child: Text(
                      '${(cubit.state['kilograms'] ?? 0.0).round()}kg',
                      style: const TextStyle(fontSize: 16.0)), // Reduced font size
                ),
              ),
              const SizedBox(height: 16.0), // Reduced spacing
              const Text(
                'Set Price/Kg:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0), // Reduced font size
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('\$0', style: TextStyle(fontSize: 14.0)), // Reduced font size
                  const Text('\$1000',
                      style: TextStyle(fontSize: 10.0, color: Colors.grey)), // Reduced font size
                ],
              ),
              Slider(
                value: cubit.state['price'] ?? 0.0,
                min: 0,
                max: 1000,
                divisions: 1000,
                label: '\$${(cubit.state['price'] ?? 0.0).round()}',
                activeColor: const Color(0xFF26A69A),
                inactiveColor: Colors.grey[300],
                onChanged: (double newPrice) {
                  cubit.updateField('price', newPrice);
                },
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(6.0), // Reduced padding
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.0), // Smaller radius
                    color: Colors.grey[200],
                  ),
                  child: Text('\$${(cubit.state['price'] ?? 0.0).round()}',
                      style: const TextStyle(fontSize: 16.0)), // Reduced font size
                ),
              ),
              const SizedBox(height: 8.0), // Reduced spacing
              const Text(
                '*Recommended Price is between \$500 and \$800 per Kg for best deals.',
                style: TextStyle(fontSize: 10.0, color: Colors.grey), // Reduced font size
              ),
              const SizedBox(height: 16.0), // Reduced spacing
              TextFormField(
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: InputDecoration(
                  labelText: 'Pick a Date For Pickup',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)), // Smaller border radius
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                controller: TextEditingController(
                  text: cubit.state['pickupDate'] != null
                      ? DateFormat('yyyy-MM-dd').format(cubit.state['pickupDate'])
                      : DateFormat('yyyy-MM-dd').format(DateTime.now()),
                ),
              ),
              const SizedBox(height: 12.0), // Reduced spacing
              TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)), // Smaller border radius
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
                onChanged: (value) => cubit.updateField('phoneNumber', value),
              ),
              const SizedBox(height: 12.0), // Reduced spacing
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      decoration: InputDecoration(
                        labelText: 'District',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)), // Smaller border radius
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your district';
                        }
                        return null;
                      },
                      onChanged: (value) => cubit.updateField('district', value),
                    ),
                  ),
                  const SizedBox(width: 12.0), // Reduced spacing
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)), // Smaller border radius
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your city';
                        }
                        return null;
                      },
                      onChanged: (value) => cubit.updateField('city', value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0), // Reduced spacing
              TextFormField(
                controller: _pickupAddressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Pickup Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)), // Smaller border radius
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your pickup address';
                  }
                  return null;
                },
                onChanged: (value) =>
                    cubit.updateField('pickupAddress', value),
              ),
              const SizedBox(height: 24.0), // Reduced spacing
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await cubit.submitForm(context);
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to submit offer: $error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12.0), // Reduced padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0), // Smaller radius
                    ),
                  ),
                  child: const Text('Sell', style: TextStyle(fontSize: 16.0)), // Reduced font size
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A524F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavBarItem(
              icon: Icons.dashboard,
              label: 'Stock',
              isSelected: false, // Set to true if this is the Stock page
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BinOwnerStockScreen(
                      userName: widget.userName,
                      user: widget.user,
                      currentIndex: 0,
                    ),
                  ),
                );
              },
            ),
            _buildNavBarItem(
              icon: Icons.home,
              label: 'Home',
              isSelected: false, // Set to true if this is the Home page
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => BinOwnerHomeScreen(currentIndex: 1),
                  ),
                  (route) => false,
                );
              },
            ),
            _buildNavBarItem(
              icon: Icons.person,
              label: 'Profile',
              isSelected: false, // Set to true if this is the Profile page
              onTap: () {
                if (widget.user != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BinOwnerProfile(user: widget.user!),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? Colors.white : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
