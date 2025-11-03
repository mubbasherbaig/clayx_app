import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'token_storage_service.dart';

class ApiService {
  static const String baseUrl = 'https://clayx-backend.onrender.com/api';

  final _tokenStorage = TokenStorageService();

  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  Future<String?> getToken() async {
    return await _tokenStorage.getToken();
  }

  Future<void> saveToken(String token) async {
    print('[API] Saving token...');
    await _tokenStorage.saveToken(token);
    print('[API] Token saved successfully');
  }

  Future<void> deleteToken() async {
    await _tokenStorage.deleteToken();
  }

  Future<void> saveUserData(Map<String, dynamic> user) async {
    try {
      await storage.write(key: 'user_id', value: user['id'].toString());
      await storage.write(key: 'user_name', value: user['fullName']);
      await storage.write(key: 'user_email', value: user['email']);
    } catch (e) {
      print('[API] Error saving user data: $e');
      rethrow;
    }
  }

  Future<Map<String, String?>> getUserData() async {
    try {
      return {
        'id': await storage.read(key: 'user_id'),
        'name': await storage.read(key: 'user_name'),
        'email': await storage.read(key: 'user_email'),
      };
    } catch (e) {
      print('[API] Error reading user data: $e');
      return {'id': null, 'name': null, 'email': null};
    }
  }

  Future<void> clearAllData() async {
    await _tokenStorage.clearAll();
    try {
      await storage.deleteAll();
    } catch (e) {
      print('[API] Error clearing storage: $e');
    }
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== AUTHENTICATION ====================

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

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('[API] Attempting login...');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['data']['token'];
        print('[API] Received token, saving...');

        await saveToken(token);

        final savedToken = await getToken();
        if (savedToken == null) {
          throw Exception('Failed to save authentication token');
        }
        print('[API] ✅ Token verified and saved successfully');

        await saveUserData(data['data']['user']);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

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
        await storage.write(key: 'user_name', value: fullName);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

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

  Future<void> logout() async {
    await clearAllData();
  }

  // ==================== PLANTS ====================

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

  Future<Map<String, dynamic>> turnPumpOn(String deviceId) async {
    return await sendDeviceCommand(
      deviceId: deviceId,
      commandType: 'pump',
      commandValue: 'on',
    );
  }

  Future<Map<String, dynamic>> turnPumpOff(String deviceId) async {
    return await sendDeviceCommand(
      deviceId: deviceId,
      commandType: 'pump',
      commandValue: 'off',
    );
  }

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

  // ==================== SENSOR DATA ====================

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

  Future<Map<String, dynamic>> getHistoricalData({
    required int plantId,
    String? startDate,
    String? endDate,
    int limit = 100,
  }) async {
    try {
      final headers = await getHeaders();

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

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

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