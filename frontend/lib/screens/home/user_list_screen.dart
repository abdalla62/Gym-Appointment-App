import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  final Map<String, String> _userImages = {};

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _loadUserImages();
  }

  Future<void> _loadUserImages() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('profile_'));
    setState(() {
      for (var key in keys) {
        _userImages[key.replaceFirst('profile_', '')] = prefs.getString(key) ?? '';
      }
    });
  }

  Future<void> _pickUserImage(String userId) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_$userId', image.path);
      setState(() {
        _userImages[userId] = image.path;
      });
    }
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.get('/auth/users');
      setState(() => _users = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.delete('/auth/users/$id');
        _fetchUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }


  Future<void> _showAddUserDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'user';
    final roles = ['user', 'trainer', 'coach', 'admin'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add New User', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, 'Name', Icons.person),
              const SizedBox(height: 12),
              _buildTextField(emailController, 'Email', Icons.email),
              const SizedBox(height: 12),
              _buildTextField(passwordController, 'Password', Icons.lock, isPassword: true),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setDialogState) => DropdownButtonFormField<String>(
                  dropdownColor: AppColors.surface,
                  value: selectedRole,
                  items: roles.map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase(), style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedRole = val!),
                  decoration: const InputDecoration(labelText: 'Role', labelStyle: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                try {
                  await _apiService.post('/auth/admin/create', {
                    'name': nameController.text,
                    'email': emailController.text,
                    'password': passwordController.text,
                    'role': selectedRole,
                  });
                  Navigator.pop(context);
                  _fetchUsers();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created successfully')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Create', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditUserDialog(Map<String, dynamic> user) async {
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    String selectedRole = user['role'] ?? 'user';
    final roles = ['user', 'trainer', 'coach', 'admin'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit User', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, 'Name', Icons.person),
              const SizedBox(height: 12),
              _buildTextField(emailController, 'Email', Icons.email),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setDialogState) => DropdownButtonFormField<String>(
                  dropdownColor: AppColors.surface,
                  value: selectedRole,
                  items: roles.map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase(), style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedRole = val!),
                  decoration: const InputDecoration(labelText: 'Role', labelStyle: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await _apiService.put('/auth/users/${user['_id']}', {
                  'name': nameController.text,
                  'email': emailController.text,
                  'role': selectedRole,
                });
                Navigator.pop(context);
                _fetchUsers();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated successfully')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Update', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
            onRefresh: _fetchUsers,
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 30,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.fitness_center, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        const Text('User Management', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                          onPressed: _showAddUserDialog,
                        ),
                      ],
                    ),
                  ),
                  Scrollbar(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final userId = user['_id'];
                        final hasCustomImage = _userImages[userId] != null && _userImages[userId]!.isNotEmpty;
                        
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _pickUserImage(userId),
                                child: CircleAvatar(
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  backgroundImage: hasCustomImage 
                                      ? FileImage(File(_userImages[userId]!))
                                      : null,
                                  child: !hasCustomImage 
                                      ? Text(user['name'] != null && user['name'].isNotEmpty ? user['name'][0].toUpperCase() : 'U', style: const TextStyle(color: AppColors.primary))
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user['name'] ?? 'Unknown User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(user['email'] ?? 'No Email', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                      child: Text((user['role'] ?? 'user').toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                                onPressed: () => _showEditUserDialog(user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                onPressed: () => _deleteUser(user['_id']),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom nav or FAB
                ],
              ),
            ),
          );
  }
}
