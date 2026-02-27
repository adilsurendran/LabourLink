import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:labourlink/login.dart';
import 'package:labourlink/worker/Register_worker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isEditMode = false;
  bool _isAvailable = true;
  final bool _useCurrentLocation = false;

  String? profileId;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _wageController = TextEditingController();
  final _uniqueIdController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  final List<String> _allSkills = [
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

  List<String> _selectedSkills = [];

  // Image
  Uint8List? _imageBytes;
  XFile? _pickedFile;
  String? _networkImage;

  final Color _primaryColor = const Color(0xFF4A00E0);
  final Color _secondaryColor = const Color(0xFF8E2DE2);
  final Color _bgColor = const Color(0xFFF8FAFF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileId = ProfileId;
      if (profileId == null) {
        setState(() => _isLoading = false);
        return;
      }
      _fetchProfile();
    });
  }

  // ================= FETCH PROFILE =================
  Future<void> _fetchProfile() async {
    try {
      final response = await dio.get("$baseurl/api/worker/profile/$profileId");
      final data = response.data;

      setState(() {
        _nameController.text = data['name'] ?? "";
        _emailController.text = data['email'] ?? "";
        _phoneController.text = data['phone_number']?.toString() ?? "";
        _dobController.text = data['dob'] ?? "";
        _ageController.text = data['age']?.toString() ?? "";
        _wageController.text = data['wage']?.toString() ?? "";
        _uniqueIdController.text = data['uniqueid'] ?? "";

        // Location logic
        if (data['location'] != null) {
          _latController.text = data['location']['lat']?.toString() ?? "";
          _lngController.text = data['location']['lng']?.toString() ?? "";
        }

        _selectedSkills = List<String>.from(data['skills'] ?? []);
        _isAvailable = data['isAvailable'] ?? true;
        _networkImage = data['photo'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Error loading profile", Colors.redAccent);
    }
  }

  // ================= LOCATION =================
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("Location services are disabled", Colors.orange);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar("Location permissions are denied", Colors.orange);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
        "Location permissions are permanently denied",
        Colors.redAccent,
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _latController.text = position.latitude.toString();
      _lngController.text = position.longitude.toString();
    });
  }

  // ================= IMAGE PICK =================
  Future<void> _pickImage() async {
    if (!_isEditMode) return;
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() {
      _pickedFile = image;
      _imageBytes = bytes;
    });
  }

  // ================= UPDATE PROFILE =================
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUpdating = true);

    try {
      FormData formData = FormData.fromMap({
        "name": _nameController.text,
        "phone_number": _phoneController.text,
        "wage": _wageController.text,
        "skills": _selectedSkills,
        "isAvailable": _isAvailable,
        "location": {"lat": _latController.text, "lng": _lngController.text},
        if (_pickedFile != null)
          "photo": MultipartFile.fromBytes(
            _imageBytes!,
            filename: _pickedFile!.name,
          ),
      });

      final response = await dio.put(
        "$baseurl/api/worker/profile/$profileId",
        data: formData,
      );

      if (response.statusCode == 200) {
        _showSnackBar("Profile Updated Successfully", Colors.green);
        setState(() => _isEditMode = false);
        await _fetchProfile();
      }
    } catch (e) {
      _showSnackBar("Update Failed", Colors.redAccent);
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ================= UI BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          "Worker Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditMode ? Icons.close_rounded : Icons.edit_note_rounded,
              color: _isEditMode ? Colors.red : _primaryColor,
            ),
            onPressed: () => setState(() {
              if (_isEditMode) {
                _pickedFile = null;
                _imageBytes = null;
                _fetchProfile(); // Reset fields
              }
              _isEditMode = !_isEditMode;
            }),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 32),
                    _buildSectionTitle("Personal Information"),
                    const SizedBox(height: 16),
                    _buildGlassCard(
                      child: Column(
                        children: [
                          _buildField(
                            _nameController,
                            "Full Name",
                            Icons.person_outline_rounded,
                          ),
                          _buildField(
                            _emailController,
                            "Email Address",
                            Icons.email_outlined,
                            readOnly: true,
                          ),
                          _buildField(
                            _phoneController,
                            "Phone Number",
                            Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                          _buildField(
                            _dobController,
                            "Date of Birth",
                            Icons.calendar_today_rounded,
                            readOnly: true,
                          ),
                          _buildField(
                            _ageController,
                            "Age",
                            Icons.cake_outlined,
                            readOnly: true,
                          ),
                          _buildField(
                            _uniqueIdController,
                            "Unique Worker ID",
                            Icons.badge_outlined,
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Work & Wage"),
                    const SizedBox(height: 16),
                    _buildGlassCard(
                      child: Column(
                        children: [
                          _buildField(
                            _wageController,
                            "Daily Wage (₹)",
                            Icons.currency_rupee_rounded,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Available for New Jobs",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                              Switch(
                                value: _isAvailable,
                                activeThumbColor: _primaryColor,
                                onChanged: _isEditMode
                                    ? (val) =>
                                          setState(() => _isAvailable = val)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Professional Skills"),
                    const SizedBox(height: 16),
                    _buildSkillsSection(),
                    const SizedBox(height: 40),
                    if (_isEditMode) _buildSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_primaryColor, _secondaryColor],
              ),
            ),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 62,
                backgroundColor: Colors.grey[200],
                backgroundImage: _imageBytes != null
                    ? MemoryImage(_imageBytes!)
                    : (_networkImage != null
                          ? NetworkImage("$baseurl/$_networkImage")
                          : null),
                child: (_imageBytes == null && _networkImage == null)
                    ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                    : null,
              ),
            ),
          ),
          if (_isEditMode)
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: _primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly || !_isEditMode,
        keyboardType: keyboardType,
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
        style: TextStyle(
          color: readOnly ? Colors.grey[600] : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          prefixIcon: Icon(
            icon,
            color: _primaryColor.withOpacity(0.7),
            size: 20,
          ),
          filled: true,
          fillColor: readOnly ? Colors.grey[50] : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[100]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _primaryColor.withOpacity(0.5)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle("Location Information"),
            if (_isEditMode)
              TextButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location_rounded, size: 18),
                label: const Text(
                  "Auto-fill",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(foregroundColor: _primaryColor),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildGlassCard(
          child: Row(
            children: [
              Expanded(
                child: _buildField(
                  _latController,
                  "Latitude",
                  Icons.explore_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildField(
                  _lngController,
                  "Longitude",
                  Icons.explore_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return _buildGlassCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _allSkills.map((skill) {
          final selected = _selectedSkills.contains(skill);
          return FilterChip(
            label: Text(
              skill,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontSize: 13,
              ),
            ),
            selected: selected,
            selectedColor: _primaryColor,
            checkmarkColor: Colors.white,
            backgroundColor: Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onSelected: _isEditMode
                ? (val) {
                    setState(() {
                      if (val) {
                        _selectedSkills.add(skill);
                      } else {
                        _selectedSkills.remove(skill);
                      }
                    });
                  }
                : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isUpdating ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 8,
          shadowColor: _primaryColor.withOpacity(0.4),
        ),
        child: _isUpdating
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "SAVE PROFILE CHANGES",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }
}
