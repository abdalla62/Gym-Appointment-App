import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get token => _user?.token;

  // Habka login-ka loogu galo nidaamka (Login functionality)
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      _user = User.fromJson(response);
      
      final prefs = await SharedPreferences.getInstance();
      if (_user!.token != null) {
        await prefs.setString('token', _user!.token!);
        await prefs.setString('userId', _user!.id);
        await prefs.setString('userRole', _user!.role);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Habka dadka cusub loogu diiwaangeliyo (Registration functionality)
  Future<void> register(String name, String email, String password, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'role': role.toLowerCase(),
      });

      _user = User.fromJson(response);
      
      final prefs = await SharedPreferences.getInstance();
      if (_user!.token != null) {
        await prefs.setString('token', _user!.token!);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  // Check if user is already logged in (Token persistence)
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;

    // Ideally we would hit /auth/me here to validate token and get user details
    // For now, we just restore generic state if needed, or force re-login
    // Extending this later.
    // We will just clear it for safety if we don't have full user data persist logic yet
    // Or we could persist User object json.
    // For MVP, user logs in each session or we implement /me
  }
}
