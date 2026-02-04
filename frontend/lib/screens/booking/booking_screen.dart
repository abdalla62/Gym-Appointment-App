import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../models/user.dart';
import 'booking_success_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  User? _selectedTrainer;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchTrainers();
    });
  }

  void _onTrainerSelected(User trainer) {
    setState(() {
      _selectedTrainer = trainer;
      _selectedTime = null;
    });
    _fetchSlots();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTime = null;
    });
    _fetchSlots();
  }

  void _fetchSlots() {
    if (_selectedTrainer != null) {
      Provider.of<AppointmentProvider>(context, listen: false).fetchAvailableSlots(
        _selectedTrainer!.id,
        DateFormat('yyyy-MM-dd').format(_selectedDate),
      );
    }
  }

  Future<void> _confirmBooking() async {
     if (_selectedTrainer == null || _selectedTime == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fadlan dooro tababare iyo waqti')));
       return;
     }

     final provider = Provider.of<AppointmentProvider>(context, listen: false);
     try {
       await provider.bookAppointment(
          _selectedTrainer!.id, 
          DateFormat('yyyy-MM-dd').format(_selectedDate), 
          _selectedTime!,
          _notesController.text
       );
       
       if (!mounted) return;
       // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment Booked Successfully!')));
       
       Navigator.pushReplacement(
         context,
         MaterialPageRoute(
           builder: (context) => BookingSuccessScreen(
             trainerName: _selectedTrainer?.name ?? 'Unknown',
             date: DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
             time: _selectedTime!,
           ),
         ),
       );
     } catch(e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Book Appointment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('SELECT TRAINER', trailing: 'Available Now'),
                  const SizedBox(height: 12),
                  _buildTrainerSelector(),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader('SELECT DATE'),
                  const SizedBox(height: 12),
                  _buildDateSelector(),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader('TIME SLOT'),
                  const SizedBox(height: 12),
                  _buildTimeGrid(),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader('NOTES FOR TRAINER'),
                  const SizedBox(height: 12),
                  _buildNotesField(),
                  
                  const SizedBox(height: 24),
                  _buildSummaryCard(),
                ],
              ),
            ),
          ),
          
          // Bottom Button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
               width: double.infinity,
               height: 56,
               child: ElevatedButton(
                 onPressed: _confirmBooking,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.primary,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 ),
                 child: const Text('Confirm Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
               ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        if (trailing != null)
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(4)),
             child: Text(trailing, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
           ),
      ],
    );
  }
  
  Widget _buildTrainerSelector() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (userProvider.trainers.isEmpty) {
          return const Text('Tababarayaal lama helin', style: TextStyle(color: Colors.grey));
        }

        return SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: userProvider.trainers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final trainer = userProvider.trainers[index];
              final isSelected = _selectedTrainer?.id == trainer.id;

              return GestureDetector(
                onTap: () => _onTrainerSelected(trainer),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? AppColors.primary : Colors.white10, width: 2),
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trainer.name,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : Colors.white,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      _onDateSelected(picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      setState(() {
        _selectedTime = DateFormat('hh:mm a').format(dt);
      });
    }
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeGrid() {
    return InkWell(
      onTap: () => _selectTime(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_filled, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              _selectedTime ?? 'Dooro waqtiga (Select Time)',
              style: TextStyle(
                color: _selectedTime != null ? Colors.white : Colors.grey,
                fontSize: 16,
                fontWeight: _selectedTime != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Share your goals or injuries...',
          hintStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), // Slightly lighter than black
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.info, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Session Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('60 min Personal Training • Power Lift Gym, Zone 3', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Text('Cancellation policy: 24h notice required.', style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
