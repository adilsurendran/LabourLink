import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:labourlink/login.dart';
import 'package:labourlink/worker/Register_worker.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _useCurrentLocation = false;

  String? _name;
  String? _phone;
  String? _place;
  String? _lat;
  String? _lng;
  String? _photoUrl;
  File? _selectedImage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  final Color _primaryColor = const Color(0xFF4A00E0);
  final Color _secondaryColor = const Color(0xFF8E2DE2);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    try {
      final response = await dio.get("$baseurl/api/user/$ProfileId");
      final data = response.data;
      setState(() {
        _name = data["name"];
        _phone = data["phone_Number"].toString();
        _place = data["place"];
        _lat = data["location"]["lat"].toString();
        _lng = data["location"]["lng"].toString();
        _photoUrl = data["photo"];

        _nameController.text = _name ?? "";
        _phoneController.text = _phone ?? "";
        _placeController.text = _place ?? "";
        _latController.text = _lat ?? "";
        _lngController.text = _lng ?? "";
      });
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load profile data")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
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

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _latController.text = position.latitude.toString();
      _lngController.text = position.longitude.toString();
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      FormData formData = FormData.fromMap({
        "name": _nameController.text,
        "phone_Number": _phoneController.text,
        "place": _placeController.text,
        "location": {"lat": _latController.text, "lng": _lngController.text},
      });

      if (_selectedImage != null) {
        formData.files.add(
          MapEntry("photo", await MultipartFile.fromFile(_selectedImage!.path)),
        );
      }

      final response = await dio.put(
        "$baseurl/api/user/update-profile/$ProfileId",
        data: formData,
      );

      if (response.data["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        _fetchUserData();
        setState(() => _isEditing = false);
      }
    } catch (e) {
      debugPrint("Update error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to update profile")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close_rounded : Icons.edit_note_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_isEditing) _selectedImage = null; // Cancel changes
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBackground(),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else
            _buildContent(),
        ],
      ),
      bottomNavigationBar: _isEditing ? _buildSaveButton() : null,
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_secondaryColor, _primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProfileImage(),
            const SizedBox(height: 30),
            _buildGlassCard(
              child: Column(
                children: [
                  _buildField(
                    "Full Name",
                    _nameController,
                    Icons.person_outline_rounded,
                  ),
                  _buildField(
                    "Phone",
                    _phoneController,
                    Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildField("Place", _placeController, Icons.place_outlined),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),
            _buildLocationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.white12,
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : (_photoUrl != null
                            ? NetworkImage("$baseurl/$_photoUrl")
                            : null)
                        as ImageProvider?,
              child: _selectedImage == null && _photoUrl == null
                  ? const Icon(Icons.person, size: 70, color: Colors.white54)
                  : null,
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: InkWell(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
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

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white70),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          disabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white10),
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "Field required" : null,
      ),
    );
  }

  Widget _buildLocationSection() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Location Data",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (_isEditing)
                Row(
                  children: [
                    const Text(
                      "Auto",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Switch(
                      value: _useCurrentLocation,
                      onChanged: (val) {
                        setState(() => _useCurrentLocation = val);
                        if (val) _getCurrentLocation();
                      },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white30,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  "Latitude",
                  _latController,
                  Icons.explore_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildField(
                  "Longitude",
                  _lngController,
                  Icons.explore_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.transparent,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(),
              )
            : const Text(
                "SAVE CHANGES",
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
      ),
    );
  }
}
