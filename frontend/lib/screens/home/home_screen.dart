import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/appointment.dart';
import '../booking/booking_screen.dart';
import 'user_list_screen.dart';
import 'availability_screen.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final ImagePicker _picker = ImagePicker();
  final Map<String, String> _customImages = {};

  @override
  void initState() {
    super.initState();
    _loadCustomImages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
      
      if (user?.role == 'admin') {
        appointmentProvider.fetchAllAppointmentsForAdmin();
        Provider.of<UserProvider>(context, listen: false).fetchSystemStats();
      } else if (user?.role == 'trainer' || user?.role == 'coach') {
        appointmentProvider.fetchTrainerAppointments();
      } else {
        appointmentProvider.fetchUserAppointments();
      }
    });
  }

  Future<void> _loadCustomImages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customImages['floor'] = prefs.getString('gym_floor') ?? '';
      _customImages['zone'] = prefs.getString('gym_zone') ?? '';
      _customImages['hub'] = prefs.getString('gym_hub') ?? '';
      _customImages['racks'] = prefs.getString('gym_racks') ?? '';
      _customImages['profile'] = prefs.getString('user_profile') ?? '';
    });
  }

  Future<void> _pickImage(String key, String prefKey) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKey, image.path);
      setState(() {
        _customImages[key] = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
        ),
      ),
      child: Scaffold(
        key: GlobalKey<ScaffoldState>(),
        backgroundColor: Colors.transparent,
        drawer: _buildDrawer(user),
        body: SafeArea(
          child: _buildBody(user, appointmentProvider),
        ),
      floatingActionButton: (user?.role == 'user' || user?.role == 'admin') && _currentIndex == 0 ? FloatingActionButton(
        onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingScreen()));
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: _buildBottomNavItems(user?.role),
      ),
    ),
  );
  }

  Widget _buildBody(user, appointmentProvider) {
    if (user?.role == 'admin') {
      switch (_currentIndex) {
        case 0: return _buildAdminDashboard(user, appointmentProvider);
        case 1: return const UserListScreen();
        case 2: return _buildAppointmentListScreen(user, appointmentProvider);
        case 3: return _buildToolsScreen(user);
        case 4: return _buildTrainerDashboard(user, appointmentProvider);
        default: return _buildAdminDashboard(user, appointmentProvider);
      }
    } else if (user?.role == 'trainer' || user?.role == 'coach') {
      switch (_currentIndex) {
        case 0: return _buildTrainerDashboard(user, appointmentProvider);
        case 1: return _buildAppointmentListScreen(user, appointmentProvider);
        case 2: return _buildAvailabilityScreen();
        case 3: return _buildToolsScreen(user);
        default: return _buildTrainerDashboard(user, appointmentProvider);
      }
    } else {
      switch (_currentIndex) {
        case 0: return _buildUserDashboard(user, appointmentProvider);
        case 1: return _buildAppointmentListScreen(user, appointmentProvider);
        case 2: return _buildSessionHistoryScreen(appointmentProvider);
        case 3: return _buildToolsScreen(user);
        default: return _buildUserDashboard(user, appointmentProvider);
      }
    }
  }

  Widget _buildDrawer(user) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _pickImage('profile', 'user_profile'),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.surface,
                    backgroundImage: _customImages['profile'] != null && _customImages['profile']!.isNotEmpty
                        ? FileImage(File(_customImages['profile']!))
                        : const NetworkImage('https://i.pravatar.cc/150?img=11') as ImageProvider,
                    child: (_customImages['profile'] == null || _customImages['profile']!.isEmpty)
                        ? const Icon(Icons.camera_alt, color: Colors.white54, size: 20)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(user?.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.white),
            title: const Text('Home', style: TextStyle(color: Colors.white)),
            onTap: () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            },
          ),
          if (user?.role == 'admin' || user?.role == 'trainer' || user?.role == 'coach') ...[
            const Divider(color: Colors.white10),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Text(user?.role == 'admin' ? 'MANAGEMENT' : 'DASHBOARD', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: AppColors.primary),
              title: const Text('Trainer Dashboard', style: TextStyle(color: Colors.white)),
              onTap: () {
                // For admin, we might need a dedicated index or just switch to trainer view
                setState(() => _currentIndex = (user?.role == 'admin' ? 4 : 0));
                Navigator.pop(context);
              },
            ),
          ],
          if (user?.role == 'admin') ...[
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.blueAccent),
              title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.white),
              title: const Text('User Management', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.white),
              title: const Text('Appointments CRUD', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
          ],
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSessionHistoryScreen(appointmentProvider) {
    final history = appointmentProvider.appointments.where((a) => a.status == 'completed' || a.status == 'cancelled').toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Session History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          history.isEmpty 
            ? const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('No past sessions found', style: TextStyle(color: Colors.grey)),
              ))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) => _buildSessionItem(
                  history[index].trainerName ?? 'Trainer',
                  '${history[index].date} • ${history[index].time}',
                  history[index].status.toUpperCase(),
                  history[index].status == 'completed' ? Colors.green : Colors.redAccent,
                  'https://i.pravatar.cc/150?u=${history[index].id}',
                ),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
              ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAppointmentListScreen(user, appointmentProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sessions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          _buildAppointmentList(user, appointmentProvider, isShrinkWrapped: true),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildToolsScreen(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gym Gallery', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('EXPLORE OUR PREMIUM FACILITIES', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildGymCard(
            'Modern Training Floor',
            'Full range of advanced weightlifting and cardio equipment.',
            _customImages['floor'] ?? '',
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=800&q=80',
            user?.role == 'admin',
            () => _pickImage('floor', 'gym_floor'),
          ),
          const SizedBox(height: 20),
          _buildGymCard(
            'Functional Zone',
            'Kettlebells, battle ropes, and turf for metabolic conditioning.',
            _customImages['zone'] ?? '',
            'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?auto=format&fit=crop&w=800&q=80',
            user?.role == 'admin',
            () => _pickImage('zone', 'gym_zone'),
          ),
          const SizedBox(height: 20),
          _buildGymCard(
            'Cardio Hub',
            'Premium treadmills with city views for your endurance sessions.',
            _customImages['hub'] ?? '',
            'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?auto=format&fit=crop&w=800&q=80',
            user?.role == 'admin',
            () => _pickImage('hub', 'gym_hub'),
          ),
          const SizedBox(height: 20),
          _buildGymCard(
            'Power Racks',
            'Dedicated spaces for heavy lifting and strength development.',
            _customImages['racks'] ?? '',
            'https://images.unsplash.com/photo-1581009146145-b5ef03a7403f?auto=format&fit=crop&w=800&q=80',
            user?.role == 'admin',
            () => _pickImage('racks', 'gym_racks'),
          ),
          const SizedBox(height: 100), // Reserve space for bottom nav
        ],
      ),
    );
  }

  Widget _buildGymCard(String title, String subtitle, String customPath, String defaultUrl, bool isAdmin, VoidCallback onUpload) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: customPath.isNotEmpty 
                  ? Image.file(
                      File(customPath),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(defaultUrl),
                    )
                  : _buildPlaceholder(defaultUrl),
              ),
              if (isAdmin)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                    child: IconButton(
                      icon: const Icon(Icons.cloud_upload, color: AppColors.primary),
                      onPressed: onUpload,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String url) {
    return Image.network(
      url,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 200,
          color: Colors.grey.withOpacity(0.1),
          child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 200,
          color: Colors.grey.withOpacity(0.2),
          child: const Icon(Icons.fitness_center, color: AppColors.primary, size: 40),
        );
      },
    );
  }

  Widget _buildAvailabilityScreen() {
    return const AvailabilityScreen();
  }

  Widget _buildProfileScreen(user) {
    return const Center(child: Text('Your Profile (Coming Soon)', style: TextStyle(color: Colors.grey)));
  }

  Widget _buildProgressScreen() {
    return const Center(child: Text('Your Progress (Coming Soon)', style: TextStyle(color: Colors.grey)));
  }

  List<BottomNavigationBarItem> _buildBottomNavItems(String? role) {
    if (role == 'admin') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Admin'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Sessions'),
        BottomNavigationBarItem(icon: Icon(Icons.build_circle), label: 'Tools'),
        BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Trainer'),
      ];
    }
    
    if (role == 'trainer' || role == 'coach') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Availability'),
        BottomNavigationBarItem(icon: Icon(Icons.build_circle), label: 'Tools'),
      ];
    }

    return const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Sessions'),
      BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
      BottomNavigationBarItem(icon: Icon(Icons.build_circle), label: 'Tools'),
    ];
  }


  Widget _buildAdminDashboard(user, appointmentProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(user),
          const SizedBox(height: 32),
          const Text('System Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              final stats = userProvider.stats;
              return Row(
                children: [
                  _buildStatCard('Total Users', stats?['totalUsers']?.toString() ?? '...', Icons.people, Colors.blue),
                  const SizedBox(width: 16),
                  _buildStatCard('Active Sessions', stats?['activeAppointments']?.toString() ?? '...', Icons.fitness_center, Colors.orange),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Recent Appointments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          _buildAppointmentList(user, appointmentProvider, isShrinkWrapped: true),
          const SizedBox(height: 32),
          const Text('Top Performing Trainers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          _buildTopTrainersList(),
        ],
      ),
    );
  }

  Widget _buildTopTrainersList() {
    return Column(
      children: [
        _buildTrainerRankItem('Ahmed Ali', '24 sessions', 'assets/trainer1.png'),
        const SizedBox(height: 12),
        _buildTrainerRankItem('Sahra Omar', '18 sessions', 'assets/trainer2.png'),
      ],
    );
  }

  Widget _buildTrainerRankItem(String name, String sessions, String img) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=$name'), radius: 20),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(sessions, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
          const Spacer(),
          const Icon(Icons.trending_up, color: Colors.green, size: 16),
        ],
      ),
    );
  }

  Widget _buildTrainerDashboard(user, appointmentProvider) {
    final completedSessions = appointmentProvider.appointments.where((a) => a.status == 'completed').length;
    final totalTrainees = appointmentProvider.appointments
        .map((a) => a.userId)
        .where((id) => id != null)
        .toSet()
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(user),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildStatCard('Total Trainees', '$totalTrainees', Icons.people, Colors.green),
              const SizedBox(width: 16),
              _buildStatCard('Completed', '$completedSessions', Icons.check_circle, Colors.blue),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Your Daily Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          _buildAppointmentList(user, appointmentProvider, isShrinkWrapped: true),
        ],
      ),
    );
  }

  Widget _buildUserDashboard(user, appointmentProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(user),
          const SizedBox(height: 32),
          _buildNextSessionHeader(),
          const SizedBox(height: 16),
          _buildNextSessionCard(),
          const SizedBox(height: 32),
          const Text('Upcoming Sessions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          _buildAppointmentList(user, appointmentProvider, isShrinkWrapped: true),
        ],
      ),
    );
  }

  Widget _buildHeader(user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            GestureDetector(
              onTap: () => _pickImage('profile', 'user_profile'),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surface,
                backgroundImage: _customImages['profile'] != null && _customImages['profile']!.isNotEmpty
                    ? FileImage(File(_customImages['profile']!))
                    : const NetworkImage('https://i.pravatar.cc/150?img=11') as ImageProvider,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.role?.toUpperCase() ?? 'USER', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                Text(user?.name ?? 'Alex Johnson', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white), 
          onPressed: () {
            Provider.of<AuthProvider>(context, listen: false).logout();
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 20),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildNextSessionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Your Next Session', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(20)),
          child: const Text('In 2 hours', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildNextSessionCard() {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(
                  'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=400&q=80',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                  child: const Text('ACTIVE NOW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Advanced Strength', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 4),
                        Text('Coach Sarah Miller • Main Gym Floor', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.fitness_center, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Today', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text('10:00 - 11:30 AM', style: TextStyle(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Check-in QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(user, appointmentProvider, {bool isShrinkWrapped = false}) {
    if (appointmentProvider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (appointmentProvider.appointments.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Text("No sessions found", style: TextStyle(color: Colors.grey)),
      ));
    }
    return ListView.separated(
      shrinkWrap: isShrinkWrapped,
      physics: isShrinkWrapped ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
      itemCount: appointmentProvider.appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointmentProvider.appointments[index];
        // final user = Provider.of<AuthProvider>(context, listen: false).user; // Passed as parameter now
        
        String displayName = 'Unknown';
        if (user?.role == 'admin') {
           displayName = '${appointment.userName} with ${appointment.trainerName}';
        } else if (user?.role == 'trainer' || user?.role == 'coach') {
           displayName = appointment.userName ?? 'Client';
        } else {
           displayName = appointment.trainerName ?? 'Trainer';
        }

        return InkWell(
          onLongPress: (user?.role == 'trainer' || user?.role == 'coach') && appointment.status == 'confirmed'
            ? () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Complete Session', style: TextStyle(color: Colors.white)),
                    content: const Text('Mark this session as completed?', style: TextStyle(color: Colors.grey)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm', style: TextStyle(color: AppColors.primary))),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await appointmentProvider.completeAppointment(appointment.id);
                }
              }
            : null,
          child: Row(
            children: [
              Expanded(
                child: _buildSessionItem(
                  displayName,
                  '${appointment.date} • ${appointment.time}\n${appointment.notes ?? "No description"}',
                  appointment.status.toUpperCase(),
                  _parseColor(appointment.scolor, appointment.status),
                  'https://i.pravatar.cc/150?u=${appointment.id}',
                ),
              ),
              if (user?.role == 'admin') ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                  onPressed: () => _showEditAppointmentDialog(appointment),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('Delete Session', style: TextStyle(color: Colors.white)),
                        content: const Text('Are you sure you want to delete this session?', style: TextStyle(color: Colors.grey)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await appointmentProvider.deleteAppointment(appointment.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session deleted')));
                    }
                  },
                ),
              ],
            ],
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
    );
  }

  Future<void> _showEditAppointmentDialog(Appointment appointment) async {
    final dateController = TextEditingController(text: appointment.date);
    final timeController = TextEditingController(text: appointment.time);
    final scolorController = TextEditingController(text: appointment.scolor);
    String selectedStatus = appointment.status;
    final statuses = ['pending', 'confirmed', 'completed', 'cancelled'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Session', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(dateController, 'Date (YYYY-MM-DD)', Icons.calendar_today),
            const SizedBox(height: 12),
            _buildDialogTextField(timeController, 'Time (HH:MM)', Icons.access_time),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              dropdownColor: AppColors.surface,
              value: selectedStatus,
              items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase(), style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (val) => selectedStatus = val!,
              decoration: const InputDecoration(labelText: 'Status', labelStyle: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 12),
            _buildDialogTextField(scolorController, 'Hex Color (e.g. #FF7F27)', Icons.color_lens),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                // We'll need to use a generic PUT for admin updates if we didn't add a specific provider method
                // Let's assume we use the provider or a direct API call
                final apiService = ApiService();
                await apiService.put('/appointments/admin/${appointment.id}', {
                   'date': dateController.text,
                   'time': timeController.text,
                   'status': selectedStatus,
                   'scolor': scolorController.text,
                });
                Navigator.pop(context);
                Provider.of<AppointmentProvider>(context, listen: false).fetchAllAppointmentsForAdmin();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session updated')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }

  Widget _buildSessionItem(String title, String subtitle, String status, Color statusColor, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
           Stack(
             children: [
               CircleAvatar(
                 radius: 28,
                 backgroundColor: Colors.grey[800],
                 backgroundImage: NetworkImage(imageUrl),
                 onBackgroundImageError: (_, __) {
                   // Fallback handled by backgroundColor
                 },
                 child: imageUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
               ),
               Positioned(
                 bottom: 0,
                 right: 0,
                 child: Container(
                   padding: const EdgeInsets.all(2),
                   decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                    child: Icon(
                        status == 'CONFIRMED' ? Icons.check_circle : Icons.access_time_filled,
                        size: 16, 
                        color: statusColor
                    ),
                 ),
               ),
             ],
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                 const SizedBox(height: 4),
                 Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                 Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
               ],
             ),
           ),
           const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Color _parseColor(String colorStr, String status) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
      }
      // Logically, we can also handle named colors if needed, but hex is primary.
    } catch (e) {
      debugPrint('Error parsing color: $e');
    }
    // Fallback logic
    return status == 'confirmed' ? AppColors.primary : (status == 'completed' ? Colors.green : Colors.amber);
  }
}
