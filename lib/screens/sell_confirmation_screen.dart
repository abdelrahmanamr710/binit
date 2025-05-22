import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SellConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> formData;

  const SellConfirmationScreen({
    super.key,
    required this.formData,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = formData['pickupDate'] != null
        ? DateFormat('yyyy-MM-dd').format(formData['pickupDate'])
        : 'Not specified';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A524F),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Center(
          child: Text(
            'Confirm Offer Details',
            style: TextStyle(color: Colors.white),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: const [SizedBox(width: 48)],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1A524F), width: 6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(
                      icon: Icons.category,
                      label: 'Material Type: ${formData['material'] ?? 'Not specified'}',
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.scale,
                      label: 'Amount: ${formData['kilograms']?.toStringAsFixed(1) ?? '0'} kg',
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.attach_money,
                      label: 'Price: ${formData['price']?.round() ?? 0} EGP/kg',
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.calculate,
                      label: 'Total Value: ${((formData['price'] ?? 0) * (formData['kilograms'] ?? 0)).round()} EGP',
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.location_city,
                      label: 'City: ${formData['city'] ?? 'Not specified'}',
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.business,
                      label: 'District: ${formData['district'] ?? 'Not specified'}',
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.location_on,
                      label: 'Pickup address: ${formData['pickupAddress'] ?? 'Not specified'}',
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.calendar_today,
                      label: 'Pick up date: $formattedDate',
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.phone,
                      label: 'Phone Number: ${formData['phoneNumber'] ?? 'Not specified'}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A524F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Confirm & Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCentered;

  const _DetailRow({
    required this.icon,
    required this.label,
    this.isCentered = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isCentered ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF1A524F)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
} 