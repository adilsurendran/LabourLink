import 'dart:ui';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:labourlink/login.dart';

// ---------------- API CONFIG ----------------
final Dio dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  ),
);

String baseurl = "";

// ---------------- REGISTER PAGE ----------------
class RegisterFormPage1 extends StatefulWidget {
  const RegisterFormPage1({super.key});

  @override
  State<RegisterFormPage1> createState() => _RegisterFormPageState();
}

class _RegisterFormPageState extends State<RegisterFormPage1>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _uniqueIdController = TextEditingController();
  final _wageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otherSkillController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Image (WEB + MOBILE)
  File? _selectedImage;
  Uint8List? _webImage;
  XFile? _pickedFile;

  DateTime? _selectedDOB;
  String _selectedGender = 'Male';

  // Location
  double? _latitude;
  double? _longitude;

  final List<String> _skills = [
    'Construction',
    'Electrician',
    'Plumber',
    'Carpenter',
    'Painter',
    'Welder',
    'Driver',
    'Mechanic',
    'Gardener',
    'Helper',
    'Mason',
    'Cook',
    'Housekeeping',
    'Security Guard',
    'Other',
  ];

  final List<String> _selectedSkills = [];
  bool _showSkillError = false;

  late final AnimationController _controller;

  final Color _primaryColor = const Color(0xFF4A00E0);
  final Color _secondaryColor = const Color(0xFF8E2DE2);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _determinePosition();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _uniqueIdController.dispose();
    _wageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otherSkillController.dispose();
    super.dispose();
  }

  // ---------------- LOCATION ----------------
  Future<void> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _latitude = pos.latitude;
      _longitude = pos.longitude;
    });
  }

  // ---------------- DOB ----------------
  Future<void> _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _selectedDOB = picked;
      _dobController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      _calculateAge(picked);
    }
  }

  void _calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    _ageController.text = age.toString();
  }

  // ---------------- IMAGE PICK ----------------
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    _pickedFile = image;

    if (kIsWeb) {
      _webImage = await image.readAsBytes();
    } else {
      _selectedImage = File(image.path);
    }

    setState(() {});
  }

  // ---------------- SUBMIT ----------------
  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();

    setState(() => _showSkillError = false);

    if (!_formKey.currentState!.validate()) return;

    if (_selectedSkills.isEmpty) {
      setState(() => _showSkillError = true);
      return;
    }

    if (_pickedFile == null) {
      _showError("Please select a profile photo");
      return;
    }

    if (_selectedDOB == null) {
      _showError("Please select Date of Birth");
      return;
    }

    if (_latitude == null || _longitude == null) {
      await _determinePosition();
    }

    if (_latitude == null || _longitude == null) {
      _showError("Unable to get location");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final skillsString = _selectedSkills
          .map((s) => s == 'Other' ? _otherSkillController.text.trim() : s)
          .where((s) => s.isNotEmpty)
          .join(', ');

      final formData = FormData.fromMap({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'uniqueid': _uniqueIdController.text.trim(),
        'wage': _wageController.text.trim(),
        'password': _passwordController.text,
        'skills': skillsString,
        'gender': _selectedGender,
        'dob': _dobController.text,
        'age': _ageController.text,
        'location': {'lat': _latitude, 'lng': _longitude},
        'photo': kIsWeb
            ? MultipartFile.fromBytes(_webImage!, filename: _pickedFile!.name)
            : await MultipartFile.fromFile(
                _selectedImage!.path,
                filename: _pickedFile!.name,
              ),
      });

      final response = await dio.post(
        '$baseurl/api/worker/register',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data['message'] ?? "Registered Successfully",
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        throw Exception("Registration failed");
      }
    } on DioException catch (e) {
      final String errorMessage =
          e.response?.data['message'] ?? "Registration failed";
      _showError(errorMessage);
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Register as Worker',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Dynamic Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_secondaryColor, _primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Floating Shapes
          Positioned(
            top: -100,
            left: -100,
            child: _buildBackgroundShape(
              size.width * 0.8,
              Colors.white.withOpacity(0.1),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: _buildBackgroundShape(
              size.width * 0.6,
              Colors.white.withOpacity(0.1),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              child: SafeArea(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _buildGlassCard(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundShape(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildAnimatedItem(
                  index: 0,
                  child: Column(
                    children: [
                      const Text(
                        "Worker Registration",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Join our network of skilled professionals",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Image Picker
                _buildAnimatedItem(index: 1, child: _buildProfileImage()),

                const SizedBox(height: 40),

                // Form Fields
                _buildAnimatedItem(
                  index: 2,
                  child: _field(
                    _nameController,
                    "Full Name",
                    Icons.person_outline,
                  ),
                ),
                _buildAnimatedItem(
                  index: 3,
                  child: _field(
                    _emailController,
                    "Email Address",
                    Icons.email_outlined,
                    validator: _validateEmail,
                  ),
                ),
                _buildAnimatedItem(
                  index: 4,
                  child: _field(
                    _phoneController,
                    "Phone Number",
                    Icons.phone_iphone,
                    isPhone: true,
                    validator: _validatePhone,
                  ),
                ),
                _buildAnimatedItem(
                  index: 5,
                  child: _field(
                    _dobController,
                    "Date of Birth",
                    Icons.calendar_month_outlined,
                    readOnly: true,
                    onTap: _pickDOB,
                  ),
                ),
                _buildAnimatedItem(
                  index: 6,
                  child: _field(
                    _ageController,
                    "Age",
                    Icons.numbers,
                    readOnly: true,
                  ),
                ),
                _buildAnimatedItem(
                  index: 7,
                  child: _field(
                    _uniqueIdController,
                    "Unique ID Number",
                    Icons.badge_outlined,
                  ),
                ),
                _buildAnimatedItem(
                  index: 8,
                  child: _field(
                    _wageController,
                    "Expected Daily Wage (₹)",
                    Icons.currency_rupee,
                    isNumber: true,
                  ),
                ),

                // Gender Selector
                _buildAnimatedItem(index: 9, child: _buildGenderSelectorUI()),

                const SizedBox(height: 20),

                _buildAnimatedItem(
                  index: 10,
                  child: _field(
                    _passwordController,
                    "Password",
                    Icons.lock_outline,
                    obscure: _obscurePassword,
                    toggleObscure: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    validator: _validatePassword,
                  ),
                ),
                _buildAnimatedItem(
                  index: 11,
                  child: _field(
                    _confirmPasswordController,
                    "Confirm Password",
                    Icons.lock_reset_outlined,
                    obscure: _obscureConfirmPassword,
                    toggleObscure: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                    validator: _validateConfirmPassword,
                  ),
                ),

                const SizedBox(height: 24),

                // Skill Selector
                _buildAnimatedItem(index: 12, child: _buildSkillSelectorUI()),

                const SizedBox(height: 32),

                // Submit Button
                _buildAnimatedItem(index: 13, child: _buildSubmitButton()),

                const SizedBox(height: 24),

                _buildAnimatedItem(
                  index: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          "Login",
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _primaryColor.withOpacity(0.2),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: _pickedFile == null
                    ? null
                    : kIsWeb
                    ? MemoryImage(_webImage!)
                    : FileImage(_selectedImage!) as ImageProvider,
                child: _pickedFile == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: Colors.grey[400],
                      )
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.add_a_photo_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelectorUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "Select Gender",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontSize: 16,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['Male', 'Female', 'Other'].map((gender) {
            bool isSelected = _selectedGender == gender;
            return GestureDetector(
              onTap: () => setState(() => _selectedGender = gender),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _primaryColor : Colors.grey[200]!,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  gender,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSkillSelectorUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "Select Your Skills",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontSize: 16,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _skills.map((skill) {
            final selected = _selectedSkills.contains(skill);
            return FilterChip(
              label: Text(skill),
              selected: selected,
              selectedColor: _primaryColor.withOpacity(0.8),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedSkills.add(skill);
                    _showSkillError = false;
                  } else {
                    _selectedSkills.remove(skill);
                    if (skill == 'Other') _otherSkillController.clear();
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_showSkillError)
          const Padding(
            padding: EdgeInsets.only(top: 8, left: 4),
            child: Text(
              "Please select at least one skill",
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        if (_selectedSkills.contains('Other'))
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _field(
              _otherSkillController,
              "Specify Other Skill",
              Icons.edit_note,
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "COMPLETE REGISTRATION",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool readOnly = false,
    VoidCallback? onTap,
    bool obscure = false,
    VoidCallback? toggleObscure,
    bool isPhone = false,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: isPhone
            ? TextInputType.phone
            : (isNumber ? TextInputType.number : TextInputType.text),
        validator:
            validator ??
            (v) => v == null || v.trim().isEmpty ? "Required" : null,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.7)),
          suffixIcon: toggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: toggleObscure,
                )
              : null,
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 20,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  // ---------------- VALIDATORS ----------------

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter email';
    const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    if (!RegExp(pattern).hasMatch(value)) return 'Invalid email';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter phone';
    if (value.length < 10) return 'Min 10 digits';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter password';
    if (value.length < 6) return 'Min 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Widget _buildAnimatedItem({required int index, required Widget child}) {
    final double startTime = (index * 0.05).clamp(0.0, 1.0);
    final double endTime = (startTime + 0.4).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startTime, endTime, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(startTime, endTime, curve: Curves.easeOutCubic),
              ),
            ),
        child: child,
      ),
    );
  }
}
