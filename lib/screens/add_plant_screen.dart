import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
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
  final ApiService _apiService = ApiService();

  String _selectedPlantType = 'Aloe Vera';
  bool _isLoading = false;

  final List<String> _plantTypes = [
    'Aloe Vera',
    'Snake Plant',
    'Peace Lily',
    'Spider Plant',
    'Pothos',
    'Monstera',
    'Succulent',
    'Fern',
    'Cactus',
    'Herbs',
    'Other',
  ];

  @override
  void dispose() {
    _plantNameController.dispose();
    _deviceIdController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleAddPlant() async {
    // Validate inputs
    if (_plantNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter plant name')),
      );
      return;
    }

    if (_deviceIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter device ID')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // First, try to register the device
      try {
        await _apiService.registerDevice(_deviceIdController.text.trim());
        print('Device registered successfully');
      } catch (e) {
        // Device might already be registered, that's okay
        print('Device registration: $e');
      }

      // Now add the plant
      final response = await _apiService.addPlant(
        plantName: _plantNameController.text.trim(),
        plantType: _selectedPlantType,
        deviceId: _deviceIdController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plant added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
              const SizedBox(height: 8),
              Text(
                'Connect your ESP32 device and name your plant',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey.withOpacity(0.8),
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
                hint: 'E.g. Tom Hardy, My Aloe',
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

              // Device ID Field with QR Scanner
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Device ID',
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
                      hintText: 'CLAYX_ESP001',
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
                  const SizedBox(height: 8),
                  Text(
                    'Enter the device ID from your ESP32 or scan QR code',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey.withOpacity(0.7),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Location Field
              CustomTextField(
                label: 'Location (Optional)',
                hint: 'E.g. Living Room, Balcony',
                controller: _locationController,
              ),

              const SizedBox(height: 32),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Make sure your ESP32 device is powered on and connected to WiFi',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryGreen,
                        ),
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