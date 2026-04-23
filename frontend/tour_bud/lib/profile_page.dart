import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tour_bud/config.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile Details',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'sans-serif',
        scaffoldBackgroundColor: const Color(0xFFEFFAD3),
      ),
      home: const ProfileDetailsScreen(),
    );
  }
}

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  static const Color teal = Color(0xFF28ABB9);
  static const Color navy = Color(0xFF2D6187);
  static const Color mintBg = Color(0xFFEFFAD3);
  static const Color sage = Color(0xFFA8DDA8);

  bool _isEditing = false;
  bool _obscurePassword = true;

  Map<String, dynamic> _originalUserData = {};
  String _createdAt = '';

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  final Map<String, String> _savedValues = {
    'full_name': '',
    'username': '',
    'password': '',
    'contact_number': '',
    'date_of_birth': '',
  };

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _contactNumberController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _onEditPressed() {
    _savedValues['full_name'] = _fullNameController.text;
    _savedValues['username'] = _usernameController.text;
    _savedValues['contact_number'] = _contactNumberController.text;
    _savedValues['date_of_birth'] = _dobController.text;
    setState(() => _isEditing = true);
  }

  void _onSavePressed() async {
    final Map<String, dynamic> updateData = {
      'full_name': _fullNameController.text.trim(),
      'username': _usernameController.text.trim(),
      'contact_number': _contactNumberController.text.trim(),
      'date_of_birth': _dobController.text.trim(),
    };

  try {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConfig.authToken}',
      },
      body: jsonEncode(updateData),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile updated successfully!")),
      );
      
      setState(() {
        _isEditing = false;
        _obscurePassword = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['error'] ?? 'Update failed')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Could not connect to server")),
    );
  }
  }

  void _onCancelPressed() {
    _fullNameController.text = _savedValues['full_name']!;
    _usernameController.text = _savedValues['username']!;
    _contactNumberController.text = _savedValues['contact_number']!;
    _dobController.text = _savedValues['date_of_birth']!;
    setState(() {
      _isEditing = false;
      _obscurePassword = true;
    });
  }

  @override
void initState() {
  super.initState();
  _fetchUserProfile();
}

Future<void> _fetchUserProfile() async {
  try {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConfig.authToken}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Adjust field names based on your API response
      final fullName = data['full_name'] ?? '';
      final contactNumber = data['contact_number'] ?? '';
      final dateOfBirth = data['date_of_birth'] ?? '';
      final createdAtValue = data['created_at'];
      String createdAtFormatted = '';

      if (createdAtValue != null) {
        if (createdAtValue is int) {
          final createdAtDate = DateTime.fromMillisecondsSinceEpoch(createdAtValue * 1000);
          createdAtFormatted = '${createdAtDate.year}-${createdAtDate.month.toString().padLeft(2, '0')}-${createdAtDate.day.toString().padLeft(2, '0')}';
        } else if (createdAtValue is String) {
          createdAtFormatted = createdAtValue;
        }
      }

      _fullNameController.text = fullName;
      _usernameController.text = data['username'] ?? '';
      _contactNumberController.text = contactNumber;
      _dobController.text = dateOfBirth;
      _createdAt = createdAtFormatted;

      // Store original data for cancel functionality
      _originalUserData = {
        'full_name': fullName,
        'username': data['username'],
        'contact_number': contactNumber,
        'date_of_birth': dateOfBirth,
      };
    } else {
      _showErrorSnackBar('Failed to load profile data');
    }
  } catch (e) {
    _showErrorSnackBar('Could not connect to server');
  }
}

void _showErrorSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 2),
    ),
  );
}

  Future<void> _selectDateOfBirth() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dobController.text.isNotEmpty
          ? DateTime.tryParse(_dobController.text) ?? DateTime(2000)
          : DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      _dobController.text =
          '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mintBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: navy.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: navy,
                        size: 18,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: navy.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: navy,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    // Avatar
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: teal, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: teal.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            size: 46,
                            color: teal,
                          ),
                        ),
                        if (_isEditing)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: navy,
                              shape: BoxShape.circle,
                              border: Border.all(color: mintBg, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: navy.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Title
                    const Text(
                      'Profile Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: navy,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Manage your personal information',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B8FA8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Form Fields
                    if (_createdAt.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Text(
                          'Created at: $_createdAt',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B8FA8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    _buildTextField(
                      label: 'Full Name',
                      controller: _fullNameController,
                      icon: Icons.badge_outlined,
                      enabled: _isEditing,
                    ),
                    _buildTextField(
                      label: 'Username',
                      controller: _usernameController,
                      icon: Icons.alternate_email_rounded,
                      enabled: _isEditing,
                    ),
                    _buildTextField(
                      label: 'Contact Number',
                      controller: _contactNumberController,
                      icon: Icons.phone_outlined,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      label: 'Date of Birth',
                      controller: _dobController,
                      icon: Icons.calendar_today_outlined,
                      enabled: _isEditing,
                      readOnly: true,
                      onTap: _isEditing ? _selectDateOfBirth : null,
                    ),

                    const SizedBox(height: 28),

                    // Buttons
                    if (!_isEditing)
                      _buildNavyButton(label: 'Edit', onTap: _onEditPressed)
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildOutlineButton(
                              label: 'Cancel',
                              onTap: _onCancelPressed,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildNavyButton(
                              label: 'Save',
                              onTap: _onSavePressed,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? teal.withOpacity(0.6) : Colors.white,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: navy.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          enabled: enabled,
          readOnly: readOnly,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onTap: onTap,
          style: const TextStyle(
            color: navy,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(
              color: navy.withOpacity(0.4),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              icon,
              color: enabled ? teal : navy.withOpacity(0.3),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavyButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: navy,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: navy.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: navy.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: navy.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'Cancel',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: navy,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
