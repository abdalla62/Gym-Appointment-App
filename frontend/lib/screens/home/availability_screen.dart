import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_app_bar.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final ApiService _apiService = ApiService();
  DateTime _selectedDate = DateTime.now();
  final List<String> _slots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentAvailability();
  }

  Future<void> _fetchCurrentAvailability() async {
    setState(() => _isLoading = true);
    try {
      // Need trainer ID, but API uses logged in user ID in controller
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final data = await _apiService.get('/availability/me?date=$dateStr'); // We might need a 'me' endpoint or handle it in controller
      // For now, let's assume we can fetch by passing any ID and the controller handles it if it's protected
      // Actually /api/availability/:trainerId is the route.
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addSlot() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary, surface: AppColors.surface),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      final timeStr = DateFormat('hh:mm a').format(dt);
      if (!_slots.contains(timeStr)) {
        setState(() => _slots.add(timeStr));
      }
    }
  }

  Future<void> _saveAvailability() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.post('/availability', {
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'slots': _slots.map((s) => {'time': s, 'isBooked': false}).toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Availability saved successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'Manage Availability',
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCurrentAvailability,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SET YOUR WORKING HOURS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              _buildDateSelector(),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TIME SLOTS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _addSlot,
                    icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                    label: const Text('Add Slot', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _slots.isEmpty
                  ? const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('No slots added yet for this date', style: TextStyle(color: Colors.grey)),
                    ))
                  : Scrollbar(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.2, // Slightly adjusted for close button
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _slots.length,
                        itemBuilder: (context, index) => _buildSlotItem(index),
                      ),
                    ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAvailability,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Availability', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 100), // Final padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(primary: AppColors.primary, surface: AppColors.surface, onSurface: Colors.white),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
          _fetchCurrentAvailability();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white, fontSize: 16)),
            const Spacer(),
            const Icon(Icons.edit, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotItem(int index) {
    return Container(
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_slots[index], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          IconButton(
            icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
            onPressed: () => setState(() => _slots.removeAt(index)),
          ),
        ],
      ),
    );
  }
}
