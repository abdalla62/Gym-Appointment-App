import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<User> _trainers = [];
  bool _isLoading = false;
  Map<String, dynamic>? _stats;

  List<User> get trainers => _trainers;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get stats => _stats;

  Future<void> fetchTrainers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> data = await _apiService.get('/auth/trainers');
      _trainers = data.map((item) => User.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error fetching trainers: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSystemStats() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.get('/auth/stats');
      _stats = data;
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
