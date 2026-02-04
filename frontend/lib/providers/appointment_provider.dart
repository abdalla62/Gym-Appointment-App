import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/availability.dart';
import '../models/appointment.dart';

class AppointmentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<Slot> _availableSlots = [];
  List<Appointment> _appointments = [];

  bool get isLoading => _isLoading;
  List<Slot> get availableSlots => _availableSlots;
  List<Appointment> get appointments => _appointments;

  Future<void> fetchUserAppointments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> data = await _apiService.get('/appointments');
      _appointments = data.map((item) => Appointment.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAvailableSlots(String trainerId, String date) async {
    _isLoading = true;
    _availableSlots = [];
    notifyListeners();

    try {
      final List<dynamic> data = await _apiService.get('/availability/$trainerId?date=$date');
      if (data.isNotEmpty) {
        final availability = Availability.fromJson(data[0]);
        _availableSlots = availability.slots;
      }
    } catch (e) {
      debugPrint('Error fetching slots: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> bookAppointment(String trainerId, String date, String time, String notes) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.post(
        '/appointments', 
        {
          'trainer': trainerId,
          'date': date,
          'time': time,
          'notes': notes,
        },
      );
      await fetchUserAppointments();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTrainerAppointments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> data = await _apiService.get('/appointments/trainer');
      _appointments = data.map((item) => Appointment.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error fetching trainer appointments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllAppointmentsForAdmin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> data = await _apiService.get('/appointments/all');
      _appointments = data.map((item) => Appointment.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error fetching all appointments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> completeAppointment(String id) async {
    try {
      await _apiService.put('/appointments/$id/status', {'status': 'completed'});
      final index = _appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        final a = _appointments[index];
        _appointments[index] = Appointment(
          id: a.id,
          date: a.date,
          time: a.time,
          status: 'completed',
          trainerId: a.trainerId,
          trainerName: a.trainerName,
          userId: a.userId,
          userName: a.userName,
          userEmail: a.userEmail,
          notes: a.notes,
          scolor: a.scolor,
          price: a.price,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking as completed: $e');
      rethrow;
    }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      await _apiService.delete('/appointments/$id');
      _appointments.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting appointment: $e');
      rethrow;
    }
  }
}
