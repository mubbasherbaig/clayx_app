import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'qr_scanner_screen.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final TextEditingController _plantNameController = TextEditingController();
  final TextEditingController _deviceIdController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _selectedPlantType = 'Aloe Vera';
  bool _isLoading = false;

  final List<String> _plantTypes = [
    'Aloe Vera',
    'Snake Plant',
    'Peace Lily',
    'Spider Plant',
    'Pothos',
    'Monstera',
  ];

  @override
  void dispose() {
    _plantNameController.dispose();
    _deviceIdController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _handleAddPlant() {
    setState(() => _isLoading = true);

    // TODO: Implement actual add plant logic with API
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plant added successfully!')),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Add Plant',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),

              const SizedBox(height: 32),

              // Plant Icon/Image Placeholder
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_florist,
                    size: 60,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Plant Name Field
              CustomTextField(
                label: 'Plant Name',
                hint: 'E.g. tom hardy',
                controller: _plantNameController,
              ),

              const SizedBox(height: 20),

              // Plant Type Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plant Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.textFieldBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPlantType,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: _plantTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() => _selectedPlantType = newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Device ID Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Device Id',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _deviceIdController,
                    decoration: InputDecoration(
                      hintText: 'Enter device id or scan QR code',
                      hintStyle: TextStyle(
                        color: AppColors.grey.withOpacity(0.5),
                        fontSize: 13,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        color: AppColors.primaryGreen,
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QRScannerScreen(),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              _deviceIdController.text = result;
                            });
                          }
                        },
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.textFieldBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.textFieldBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryGreen,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Location Field
              CustomTextField(
                label: 'Location',
                hint: 'E.g. living Room',
                controller: _locationController,
              ),

              const SizedBox(height: 24),

              // Add Photo Button
              OutlinedButton(
                onPressed: () {
                  // TODO: Implement image picker
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: AppColors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, color: AppColors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Add Photo (optional)',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Add Plant Button
              CustomButton(
                text: 'Add Plant',
                onPressed: _handleAddPlant,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: AppColors.grey.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}