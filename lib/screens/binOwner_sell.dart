import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:binit/screens/sell_requested.dart';
import 'package:binit/models/user_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:binit/screens/binOwner_stock.dart';
import 'package:binit/screens/binOwner_homescreen.dart';
import 'package:binit/screens/binOwner_profile.dart';
import 'package:animations/animations.dart';
import 'package:binit/screens/sell_confirmation_screen.dart';

// Define a Cubit for managing the SellForm state
class SellFormCubit extends Cubit<Map<String, dynamic>> {
  SellFormCubit() : super({
    'kilograms': 0.0,
    'price': 100.0, // Initialize with default base price
    'pickupDate': DateTime.now(),
  });

  void updateField(String field, dynamic value) {
    emit({...state, field: value});
  }

  Future<void> submitForm(BuildContext context) async {
    await Firebase.initializeApp();
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      throw Exception('User not logged in');
    }

    // Start a batch write
    final WriteBatch batch = firestore.batch();

    try {
      // 1. Get all bins owned by the user
      final binsSnapshot = await firestore
          .collection('registered_bins')
          .where('owners', arrayContains: userId)
          .get();

      if (binsSnapshot.docs.isEmpty) {
        throw Exception('No bins found for user');
      }

      // 2. Calculate total weight and prepare for deduction
      double totalWeight = 0;
      final material = state['material'] as String;
      final weightToDeduct = state['kilograms'] as double;
      
      final bins = binsSnapshot.docs.map((doc) {
        final data = doc.data();
        final binWeight = material.toLowerCase() == 'plastic'
            ? (data['plastic_total_weight'] as num?)?.toDouble() ?? 0.0
            : (data['metal_total_weight'] as num?)?.toDouble() ?? 0.0;
        totalWeight += binWeight;
        return {
          'ref': doc.reference,
          'weight': binWeight,
          'data': data,
        };
      }).toList();

      // 3. Verify if there's enough weight
      if (totalWeight < weightToDeduct) {
        throw Exception('Insufficient stock available. Available: ${totalWeight}kg, Required: ${weightToDeduct}kg');
      }

      // 4. Deduct weight proportionally from each bin
      for (final bin in bins) {
        final binWeight = bin['weight'] as double;
        if (binWeight > 0) {
          final proportion = binWeight / totalWeight;
          final weightToDeductFromBin = weightToDeduct * proportion;
          
          final updateField = material.toLowerCase() == 'plastic'
              ? 'plastic_total_weight'
              : 'metal_total_weight';
          
          final binData = bin['data'] as Map<String, dynamic>;
          final currentWeight = material.toLowerCase() == 'plastic'
              ? (binData['plastic_total_weight'] as num).toDouble()
              : (binData['metal_total_weight'] as num).toDouble();

          final updates = {
            updateField: currentWeight - weightToDeductFromBin,
            'lastUpdated': FieldValue.serverTimestamp(),
            material.toLowerCase() == 'plastic' ? 'plastic_emptied' : 'metal_emptied': false,
            material.toLowerCase() == 'plastic' ? 'plastic_last_emptied' : 'metal_last_emptied': FieldValue.serverTimestamp(),
          };

          batch.update(bin['ref'] as DocumentReference, updates);
        }
      }

      // 5. Create the sell offer document
      final offerRef = firestore.collection('sell_offers').doc();
      batch.set(offerRef, {
        'kilograms': weightToDeduct,
        'price': state['price'],
        'pickupDate': state['pickupDate'],
        'phoneNumber': state['phoneNumber'],
        'district': state['district'],
        'city': state['city'],
        'pickupAddress': state['pickupAddress'],
        'userId': userId,
        'status': 'pending',
        'date': FieldValue.serverTimestamp(),
        'material': material,
      });

      // 6. Create a weight deduction record
      final deductionRef = firestore.collection('weight_deductions').doc();
      batch.set(deductionRef, {
        'offerId': offerRef.id,
        'userId': userId,
        'material': material,
        'totalWeightDeducted': weightToDeduct,
        'timestamp': FieldValue.serverTimestamp(),
        'bins': bins.map((bin) {
          final binWeight = bin['weight'] as double;
          return {
            'binId': (bin['ref'] as DocumentReference).id,
            'weightBefore': binWeight,
            'deductedWeight': binWeight > 0
                ? (weightToDeduct * (binWeight / totalWeight))
                : 0,
          };
        }).toList(),
      });

      // 7. Commit all changes
      await batch.commit();

      // 8. Reset form state
      emit({
        'kilograms': 0.0,
        'price': 0.0,
        'pickupDate': DateTime.now(),
      });

      print('Form data submitted successfully!');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SellDone(userName: '', user: null),
        ),
      );
    } catch (error) {
      print('Error submitting form: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
      throw error;
    }
  }
}

class BinOwnerSell extends StatelessWidget {
  final String userName;
  final UserModel? user;
  final String? initialMaterial;

  const BinOwnerSell({super.key, required this.userName, this.user, this.initialMaterial});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellFormCubit(),
      child: UserSellForm(userName: userName, user: user, initialMaterial: initialMaterial),
    );
  }
}

class UserSellForm extends StatefulWidget {
  final String userName;
  final UserModel? user;
  final String? initialMaterial;
  const UserSellForm({super.key, required this.userName, this.user, this.initialMaterial});

  @override
  _UserSellFormState createState() => _UserSellFormState();
}

class _UserSellFormState extends State<UserSellForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _pickupAddressController = TextEditingController();

  String _selectedMaterial = 'Plastic';
  double _maxStock = 0.0;
  bool _loadingStock = true;
  double _basePrice = 100.0; // Default price
  bool _loadingPrice = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialMaterial != null) {
      _selectedMaterial = widget.initialMaterial!;
      // Set initial material in cubit state
      context.read<SellFormCubit>().updateField('material', _selectedMaterial);
    }
    _fetchStock();
    _fetchPriceConfig();
  }

  Future<void> _fetchStock() async {
    setState(() { _loadingStock = true; });
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final bins = await FirebaseFirestore.instance
        .collection('registered_bins')
        .where('owners', arrayContains: userId)
        .get();
    double total = 0.0;
    for (var bin in bins.docs) {
      final data = bin.data();
      if (_selectedMaterial == 'Plastic') {
        total += (data['plastic_total_weight'] as num?)?.toDouble() ?? 0.0;
      } else {
        total += (data['metal_total_weight'] as num?)?.toDouble() ?? 0.0;
      }
    }
    setState(() {
      _maxStock = total;
      _loadingStock = false;
    });
  }

  Future<void> _fetchPriceConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('prices')
          .get();

      if (doc.exists) {
        final newBasePrice = (doc.data()?['base_price_per_kg'] as num?)?.toDouble() ?? 100.0;
        setState(() {
          _basePrice = newBasePrice;
          _loadingPrice = false;
        });
        // Update the cubit's price to the base price
        context.read<SellFormCubit>().updateField('price', newBasePrice);
      } else {
        // Initialize the price config if it doesn't exist
        await FirebaseFirestore.instance
            .collection('config')
            .doc('prices')
            .set({
          'base_price_per_kg': 100.0,
          'currency': 'EGP',
          'last_updated': FieldValue.serverTimestamp(),
        });
        setState(() {
          _basePrice = 100.0;
          _loadingPrice = false;
        });
        // Update the cubit's price to the default base price
        context.read<SellFormCubit>().updateField('price', 100.0);
      }
    } catch (e) {
      print('Error fetching price config: $e');
      setState(() {
        _basePrice = 100.0;
        _loadingPrice = false;
      });
      // Update the cubit's price to the default base price
      context.read<SellFormCubit>().updateField('price', 100.0);
    }
  }

  void _onMaterialChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedMaterial = value;
    });
    // Update material in cubit state when changed
    context.read<SellFormCubit>().updateField('material', value);
    _fetchStock();
  }

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

  void _navigateWithFadeThrough(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: page,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
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
      body: _loadingStock || _loadingPrice
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Set Weight to be Sold:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('0kg', style: TextStyle(fontSize: 14.0)),
                        Text('Max: ${_maxStock.toStringAsFixed(1)}kg',
                            style: const TextStyle(fontSize: 10.0, color: Colors.grey)),
                      ],
                    ),
                    Slider(
                      value: (cubit.state['kilograms'] ?? 0.0).clamp(0.0, _maxStock),
                      min: 0,
                      max: _maxStock > 0 ? _maxStock : 1,
                      divisions: _maxStock > 0 ? _maxStock.round() : 1,
                      label: '${(cubit.state['kilograms'] ?? 0.0).round()}kg',
                      activeColor: const Color(0xFF26A69A),
                      inactiveColor: Colors.grey[300],
                      onChanged: _maxStock > 0
                          ? (double newWeight) {
                              cubit.updateField('kilograms', newWeight);
                            }
                          : null,
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.0),
                          color: Colors.grey[200],
                        ),
                        child: Text(
                          '${(cubit.state['kilograms'] ?? 0.0).round()}kg',
                          style: const TextStyle(fontSize: 16.0)),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Set Price/Kg:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${(_basePrice * 0.7).round()} EGP', 
                            style: const TextStyle(fontSize: 14.0)),
                        Text('${(_basePrice * 1.3).round()} EGP',
                            style: const TextStyle(fontSize: 10.0, color: Colors.grey)),
                      ],
                    ),
                    Slider(
                      value: (cubit.state['price'] ?? _basePrice).clamp(_basePrice * 0.7, _basePrice * 1.3),
                      min: _basePrice * 0.7,
                      max: _basePrice * 1.3,
                      divisions: ((_basePrice * 0.6).round()),
                      label: '${(cubit.state['price'] ?? _basePrice).round()} EGP',
                      activeColor: const Color(0xFF26A69A),
                      inactiveColor: Colors.grey[300],
                      onChanged: (double newPrice) {
                        cubit.updateField('price', newPrice);
                      },
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.0),
                          color: Colors.grey[200],
                        ),
                        child: Text('${(cubit.state['price'] ?? _basePrice).round()} EGP',
                            style: const TextStyle(fontSize: 16.0)),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      '*Recommended Price is between ${(_basePrice * 0.9).round()} and ${(_basePrice * 1.1).round()} EGP per Kg for best deals.',
                      style: const TextStyle(fontSize: 10.0, color: Colors.grey),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      decoration: InputDecoration(
                        labelText: 'Pick a Date For Pickup',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                      controller: TextEditingController(
                        text: cubit.state['pickupDate'] != null
                            ? DateFormat('yyyy-MM-dd').format(cubit.state['pickupDate'])
                            : DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    TextFormField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                      onChanged: (value) => cubit.updateField('phoneNumber', value),
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _districtController,
                            decoration: InputDecoration(
                              labelText: 'District',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
                    const SizedBox(height: 12.0),
                    TextFormField(
                      controller: _pickupAddressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Pickup Address',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
                    const SizedBox(height: 24.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Show confirmation screen instead of submitting directly
                            final confirmed = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SellConfirmationScreen(
                                  formData: {
                                    ...cubit.state,
                                    'material': _selectedMaterial,
                                  },
                                ),
                              ),
                            );
                            
                            if (confirmed == true) {
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
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF26A69A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: const Text('Review Offer', style: TextStyle(fontSize: 16.0)),
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
              isSelected: false,
              onTap: () {
                _navigateWithFadeThrough(BinOwnerStockScreen(
                  userName: widget.userName,
                  user: widget.user,
                  currentIndex: 0,
                ));
              },
            ),
            _buildNavBarItem(
              icon: Icons.home,
              label: 'Home',
              isSelected: false,
              onTap: () {
                _navigateWithFadeThrough(BinOwnerHomeScreen(currentIndex: 1));
              },
            ),
            _buildNavBarItem(
              icon: Icons.person,
              label: 'Profile',
              isSelected: false,
              onTap: () {
                if (widget.user != null) {
                  _navigateWithFadeThrough(BinOwnerProfile(user: widget.user!));
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
