import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Habka macluumaadka loogu diro server-ka (Method to send data to server)
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }

  // Habka xogta looga soo aqriyo server-ka (Method to fetch data from server)
  Future<dynamic> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: headers,
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: headers,
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    // Attempt to decode JSON
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (e) {
      body = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      if (body is Map && body.containsKey('message')) {
        throw Exception(body['message']);
      }
      throw Exception('Error ${response.statusCode}');
    }
  }
}
// file