import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:binit/screens/sell_requested.dart';
import 'package:binit/models/user_model.dart'; // Import UserModel


// Define a Cubit for managing the SellForm state
class SellFormCubit extends Cubit<Map<String, dynamic>> {
  SellFormCubit() : super({});

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
      emit({});
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

  double _kilogramsValue = 0;
  double _priceValue = 0;
  DateTime _selectedDate = DateTime.now();

  // Function to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final SellFormCubit cubit = context.read<SellFormCubit>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      cubit.updateField('pickupDate', _selectedDate);
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
        title: const Text('Sell Recyclable Material',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Kilograms Slider
                const Text(
                  'Kilograms',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _kilogramsValue,
                  min: 0,
                  max: 1000,
                  divisions: 100,
                  label: _kilogramsValue.round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      _kilogramsValue = value;
                    });
                    cubit.updateField('kilograms', value);
                  },
                ),
                Text('Selected Kilograms: ${_kilogramsValue.round()} kg'),
                const SizedBox(height: 20),
                // Price Slider
                const Text(
                  'Price',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _priceValue,
                  min: 0,
                  max: 10000,
                  divisions: 100,
                  label: _priceValue.round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      _priceValue = value;
                    });
                    cubit.updateField('price', value);
                  },
                ),
                Text('Selected Price: \$${_priceValue.round()}'),
                const SizedBox(height: 20),
                // Pickup Date
                const Text(
                  'Pickup Date',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: <Widget>[
                    Text(
                      "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Phone Number
                TextFormField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                  onChanged: (value) => cubit.updateField('phoneNumber', value),
                ),
                const SizedBox(height: 20),
                // District
                TextFormField(
                  controller: _districtController,
                  decoration: const InputDecoration(
                    labelText: 'District',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your district';
                    }
                    return null;
                  },
                  onChanged: (value) => cubit.updateField('district', value),
                ),
                const SizedBox(height: 20),
                // City
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your city';
                    }
                    return null;
                  },
                  onChanged: (value) => cubit.updateField('city', value),
                ),
                const SizedBox(height: 20),
                // Pickup Address
                TextFormField(
                  controller: _pickupAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Pickup Address Details',
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        // Pass the context to the cubit's submitForm method.
                        await cubit.submitForm(context);
                        // The navigation to SellDone is now handled in the cubit.
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
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('Submit Offer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

