import 'package:flutter/material.dart';

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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  final Map<String, String> _savedValues = {
    'name': '',
    'surname': '',
    'username': '',
    'password': '',
    'email': '',
    'mobile': '',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _onEditPressed() {
    _savedValues['name'] = _nameController.text;
    _savedValues['surname'] = _surnameController.text;
    _savedValues['username'] = _usernameController.text;
    _savedValues['password'] = _passwordController.text;
    _savedValues['email'] = _emailController.text;
    _savedValues['mobile'] = _mobileController.text;
    setState(() => _isEditing = true);
  }

  void _onSavePressed() {
    setState(() {
      _isEditing = false;
      _obscurePassword = true;
    });
  }

  void _onCancelPressed() {
    _nameController.text = _savedValues['name']!;
    _surnameController.text = _savedValues['surname']!;
    _usernameController.text = _savedValues['username']!;
    _passwordController.text = _savedValues['password']!;
    _emailController.text = _savedValues['email']!;
    _mobileController.text = _savedValues['mobile']!;
    setState(() {
      _isEditing = false;
      _obscurePassword = true;
    });
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
                    _buildTextField(
                      label: 'Name',
                      controller: _nameController,
                      icon: Icons.badge_outlined,
                      enabled: _isEditing,
                    ),
                    _buildTextField(
                      label: 'Surname',
                      controller: _surnameController,
                      icon: Icons.person_outlined,
                      enabled: _isEditing,
                    ),
                    _buildTextField(
                      label: 'Username',
                      controller: _usernameController,
                      icon: Icons.alternate_email_rounded,
                      enabled: _isEditing,
                    ),
                    _buildPasswordField(),
                    _buildTextField(
                      label: 'Email Address',
                      controller: _emailController,
                      icon: Icons.mail_outline_rounded,
                      enabled: _isEditing,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      label: 'Mobile Number',
                      controller: _mobileController,
                      icon: Icons.phone_outlined,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
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
          obscureText: obscureText,
          keyboardType: keyboardType,
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

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isEditing ? teal.withOpacity(0.6) : Colors.white,
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
          controller: _passwordController,
          enabled: _isEditing,
          obscureText: _obscurePassword,
          style: const TextStyle(
            color: navy,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Password',
            hintStyle: TextStyle(
              color: navy.withOpacity(0.4),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: _isEditing ? teal : navy.withOpacity(0.3),
              size: 20,
            ),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _isEditing ? teal : navy.withOpacity(0.3),
                size: 20,
              ),
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
