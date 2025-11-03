import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // CHANGE THIS to your Render URL!
  static const String baseUrl = 'https://clayx-backend.onrender.com/api';

// Add Android options to prevent the error
  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

// ==================== TOKEN MANAGEMENT ====================

// Get stored token with error handling
  Future<String?> getToken() async {
    try {
      return await storage.read(key: 'auth_token');
    } catch (e) {
      print('Error reading token: $e');
      return null;
    }
  }

// Save token with error handling
  Future<void> saveToken(String token) async {
    try {
      await storage.write(key: 'auth_token', value: token);
    } catch (e) {
      print('Error saving token: $e');
      rethrow;
    }
  }

// Delete token with error handling
  Future<void> deleteToken() async {
    try {
      await storage.delete(key: 'auth_token');
    } catch (e) {
      print('Error deleting token: $e');
    }
  }

// Save user data with error handling
  Future<void> saveUserData(Map<String, dynamic> user) async {
    try {
      await storage.write(key: 'user_id', value: user['id'].toString());
      await storage.write(key: 'user_name', value: user['fullName']);
      await storage.write(key: 'user_email', value: user['email']);
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

// Get user data with error handling
  Future<Map<String, String?>> getUserData() async {
    try {
      return {
        'id': await storage.read(key: 'user_id'),
        'name': await storage.read(key: 'user_name'),
        'email': await storage.read(key: 'user_email'),
      };
    } catch (e) {
      print('Error reading user data: $e');
      return {'id': null, 'name': null, 'email': null};
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    await storage.deleteAll();
  }

  // Get headers with authorization
  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== AUTHENTICATION ====================

  // Register new user
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Save token and user data
        await saveToken(data['data']['token']);
        await saveUserData(data['data']['user']);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> sendDeviceCommand({
    required String deviceId,
    required String commandType,
    required String commandValue,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sensor/commands'),
        headers: headers,
        body: jsonEncode({
          'deviceId': deviceId,
          'commandType': commandType,
          'commandValue': commandValue,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to send command');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Turn pump on
  Future<Map<String, dynamic>> turnPumpOn(String deviceId) async {
    return await sendDeviceCommand(
      deviceId: deviceId,
      commandType: 'pump',
      commandValue: 'on',
    );
  }

  // Turn pump off
  Future<Map<String, dynamic>> turnPumpOff(String deviceId) async {
    return await sendDeviceCommand(
      deviceId: deviceId,
      commandType: 'pump',
      commandValue: 'off',
    );
  }

  // Get command history for a device
  Future<Map<String, dynamic>> getCommandHistory({
    required String deviceId,
    int limit = 50,
  }) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse(
        '$baseUrl/sensor/device/$deviceId/commands/history',
      ).replace(queryParameters: {'limit': limit.toString()});

      final response = await http.get(uri, headers: headers);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to get command history');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save token and user data
        await saveToken(data['data']['token']);
        await saveUserData(data['data']['user']);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to get profile');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({required String fullName}) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: headers,
        body: jsonEncode({'fullName': fullName}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update stored user data
        await storage.write(key: 'user_name', value: fullName);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Forgot password
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to send reset link');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Logout
  Future<void> logout() async {
    await clearAllData();
  }

  // ==================== PLANTS ====================

  // Get all plants
  Future<Map<String, dynamic>> getPlants() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/plants'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to get plants');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Get single plant by ID
  Future<Map<String, dynamic>> getPlantById(int plantId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/plants/$plantId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to get plant');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Add new plant
  Future<Map<String, dynamic>> addPlant({
    required String plantName,
    required String plantType,
    required String deviceId,
    String? location,
    String? imageUrl,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/plants'),
        headers: headers,
        body: jsonEncode({
          'plantName': plantName,
          'plantType': plantType,
          'deviceId': deviceId,
          'location': location,
          'imageUrl': imageUrl,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to add plant');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Update plant
  Future<Map<String, dynamic>> updatePlant({
    required int plantId,
    String? plantName,
    String? plantType,
    String? location,
    String? imageUrl,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/plants/$plantId'),
        headers: headers,
        body: jsonEncode({
          if (plantName != null) 'plantName': plantName,
          if (plantType != null) 'plantType': plantType,
          if (location != null) 'location': location,
          if (imageUrl != null) 'imageUrl': imageUrl,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update plant');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Delete plant
  Future<Map<String, dynamic>> deletePlant(int plantId) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/plants/$plantId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to delete plant');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Get plant care timeline
  Future<Map<String, dynamic>> getPlantTimeline(int plantId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/plants/$plantId/timeline'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to get timeline');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Water plant (log watering event)
  Future<Map<String, dynamic>> waterPlant(int plantId) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/plants/$plantId/water'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to log watering');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // ==================== DEVICES ====================

  // Get all devices
  Future<Map<String, dynamic>> getDevices() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/devices'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to get devices');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Get single device by ID
  Future<Map<String, dynamic>> getDeviceById(int deviceId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/devices/$deviceId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to get device');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Register new device
  Future<Map<String, dynamic>> registerDevice(String deviceId) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/devices'),
        headers: headers,
        body: jsonEncode({'deviceId': deviceId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to register device');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Update device
  Future<Map<String, dynamic>> updateDevice({
    required int deviceId,
    required bool isOnline,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/devices/$deviceId'),
        headers: headers,
        body: jsonEncode({'isOnline': isOnline}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update device');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Delete device
  Future<Map<String, dynamic>> deleteDevice(int deviceId) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/devices/$deviceId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to delete device');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // ==================== SENSOR DATA ====================

  // Post sensor data (from ESP - no auth required)
  Future<Map<String, dynamic>> postSensorData({
    required String deviceId,
    double? temperature,
    double? humidity,
    double? soilMoisture,
    double? waterLevel,
    String? lightLevel,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sensor/data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': deviceId,
          'temperature': temperature,
          'humidity': humidity,
          'soilMoisture': soilMoisture,
          'waterLevel': waterLevel,
          'lightLevel': lightLevel,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to post sensor data');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Get latest sensor reading for a plant
  Future<Map<String, dynamic>> getLatestReading(int plantId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/sensor/plants/$plantId/latest'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to get latest reading');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // Get historical sensor data
  Future<Map<String, dynamic>> getHistoricalData({
    required int plantId,
    String? startDate,
    String? endDate,
    int limit = 100,
  }) async {
    try {
      final headers = await getHeaders();

      // Build query parameters
      final queryParams = {
        'limit': limit.toString(),
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final uri = Uri.parse(
        '$baseUrl/sensor/plants/$plantId/history',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to get historical data');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // ==================== HELPER METHODS ====================

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Test API connection
  Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl.replaceAll('/api', '')))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
