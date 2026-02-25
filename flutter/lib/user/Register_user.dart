import 'dart:ui';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:labourlink/login.dart';
import 'package:labourlink/worker/Register_worker.dart';

class RegisterFormPage extends StatefulWidget {
  const RegisterFormPage({super.key});

  @override
  State<RegisterFormPage> createState() => _RegisterFormPageState();
}

class _RegisterFormPageState extends State<RegisterFormPage>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _nameController = TextEditingController();
  final _placeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final Dio _dio = Dio();

  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Image
  File? _selectedImage;
  Uint8List? _webImage;
  XFile? _pickedFile;

  // Location
  double? _latitude;
  double? _longitude;

  late final AnimationController _controller;

  final Color _primaryColor = const Color(0xFF4A00E0);
  final Color _secondaryColor = const Color(0xFF8E2DE2);

  // ---------------- IMAGE PICK ----------------

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    _pickedFile = picked;

    if (kIsWeb) {
      _webImage = await picked.readAsBytes();
    } else {
      _selectedImage = File(picked.path);
    }

    setState(() {});
  }

  // ---------------- LOCATION ----------------

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });
  }

  // ---------------- LIFECYCLE ----------------

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
    _placeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ---------------- SUBMIT ----------------

  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      await _determinePosition();
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unable to fetch location")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      FormData formData = FormData.fromMap({
        "name": _nameController.text.trim(),
        "place": _placeController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
        "password": _passwordController.text,
        "location": {"lat": _latitude, "lng": _longitude},
        if (_pickedFile != null)
          "profile_image": kIsWeb
              ? MultipartFile.fromBytes(_webImage!, filename: _pickedFile!.name)
              : await MultipartFile.fromFile(
                  _selectedImage!.path,
                  filename: _pickedFile!.name,
                ),
      });

      final response = await _dio.post(
        "$baseurl/api/user/register",
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

        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
      } else {
        throw Exception("Registration failed");
      }
    } on DioException catch (e) {
      final String errorMessage =
          e.response?.data['message'] ?? "Registration failed";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    setState(() => _isSubmitting = false);
  }

  // ---------------- VALIDATORS ----------------

  String? _validateName(String? value) => value == null || value.trim().isEmpty
      ? 'Enter name'
      : value.length < 3
      ? 'Min 3 characters'
      : null;

  String? _validatePlace(String? value) => value == null || value.trim().isEmpty
      ? 'Enter place'
      : value.length < 3
      ? 'Min 3 characters'
      : null;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Enter email';
    const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    if (!RegExp(pattern).hasMatch(value)) return 'Invalid email';
    return null;
  }

  String? _validatePhone(String? value) => value == null || value.isEmpty
      ? 'Enter phone'
      : value.length < 10
      ? 'Min 10 digits'
      : null;

  String? _validatePassword(String? value) => value == null || value.isEmpty
      ? 'Enter password'
      : value.length < 6
      ? 'Min 6 characters'
      : null;

  String? _validateConfirmPassword(String? value) =>
      value != _passwordController.text ? 'Passwords do not match' : null;

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Create User Account',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 1. Dynamic Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_secondaryColor, _primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Floating Shapes for visual interest
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
          Positioned(
            top: size.height * 0.4,
            right: -50,
            child: _buildBackgroundShape(150, Colors.white.withOpacity(0.05)),
          ),

          // 2. Main Content
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
                        "Join LabourLink",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Fill in your details to get started",
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Premium Image Picker
                _buildAnimatedItem(
                  index: 1,
                  child: Center(
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
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
                  ),
                ),

                const SizedBox(height: 40),

                _buildAnimatedItem(
                  index: 2,
                  child: _field(
                    _nameController,
                    "Full Name",
                    Icons.person_outline_rounded,
                    _validateName,
                  ),
                ),
                _buildAnimatedItem(
                  index: 3,
                  child: _field(
                    _placeController,
                    "City / Region",
                    Icons.map_outlined,
                    _validatePlace,
                  ),
                ),
                _buildAnimatedItem(
                  index: 4,
                  child: _field(
                    _emailController,
                    "Email Address",
                    Icons.email_outlined,
                    _validateEmail,
                  ),
                ),
                _buildAnimatedItem(
                  index: 5,
                  child: _field(
                    _phoneController,
                    "Phone Number",
                    Icons.phone_iphone_rounded,
                    _validatePhone,
                  ),
                ),
                _buildAnimatedItem(index: 6, child: _passwordField()),
                _buildAnimatedItem(index: 7, child: _confirmPasswordField()),

                const SizedBox(height: 32),

                _buildAnimatedItem(
                  index: 8,
                  child: Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [_primaryColor, _secondaryColor],
                      ),
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
                              "CREATE ACCOUNT",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                _buildAnimatedItem(
                  index: 9,
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

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon,
    String? Function(String?) validator,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: c,
        validator: validator,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.7)),
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
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _passwordField() => _fieldWithToggle(
    controller: _passwordController,
    label: "Password",
    obscure: _obscurePassword,
    toggle: () => setState(() => _obscurePassword = !_obscurePassword),
    validator: _validatePassword,
  );

  Widget _confirmPasswordField() => _fieldWithToggle(
    controller: _confirmPasswordController,
    label: "Confirm Password",
    obscure: _obscureConfirmPassword,
    toggle: () =>
        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
    validator: _validateConfirmPassword,
  );

  Widget _fieldWithToggle({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: _primaryColor.withOpacity(0.7),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey[400],
              size: 20,
            ),
            onPressed: toggle,
          ),
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
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
      ),
    );
  }

  // Animation Helper for premium staggered effect
  Widget _buildAnimatedItem({required int index, required Widget child}) {
    final double startTime = (index * 0.08).clamp(0.0, 1.0);
    final double endTime = (startTime + 0.4).clamp(0.0, 1.0);

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startTime, endTime, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
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
