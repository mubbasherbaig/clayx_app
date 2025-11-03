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
  bool _isDarkMode = false;

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
      try {
        await _apiService.registerDevice(_deviceIdController.text.trim());
      } catch (e) {
        print('Device registration: $e');
      }

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
        Navigator.pop(context, true);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Plant',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: AppColors.grey,
            ),
            onPressed: () {
              setState(() => _isDarkMode = !_isDarkMode);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    'assets/images/icons/add_plant_icon.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                label: 'Plant Name',
                hint: 'E.g., Fern Gully',
                controller: _plantNameController,
              ),
              const SizedBox(height: 20),
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
                      hintText: 'Enter device ID or scan QR code',
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
              CustomTextField(
                label: 'Location',
                hint: 'E.g., Living Room',
                controller: _locationController,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement image picker
                },
                icon: const Icon(Icons.photo_camera, color: AppColors.grey),
                label: const Text(
                  'Add Photo (Optional)',
                  style: TextStyle(color: AppColors.grey),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: BorderSide(
                    color: AppColors.grey.withOpacity(0.3),
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Add Plant',
                onPressed: _handleAddPlant,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
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
            ],
          ),
        ),
      ),
    );
  }
}