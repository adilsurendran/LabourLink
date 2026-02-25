import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:labourlink/login.dart'; // For ProfileId
import 'package:labourlink/worker/Register_worker.dart'; // For dio & baseurl

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

  String? profileId;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _wageController = TextEditingController();
  final _uniqueIdController = TextEditingController();
  final _otherSkillController = TextEditingController();

  final List<String> _allSkills = [
    'Construction','Electrician','Plumber','Carpenter','Painter',
    'Welder','Driver','Mechanic','Gardener','Helper',
    'Mason','Cook','Housekeeping','Security Guard','Other',
  ];

  List<String> _selectedSkills = [];

  // Image
  Uint8List? _imageBytes;
  XFile? _pickedFile;
  String? _networkImage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileId = ProfileId;

      if (profileId == null) {
        debugPrint("ProfileId is NULL");
        setState(() => _isLoading = false);
        return;
      }

      _fetchProfile();
    });
  }

  // ================= FETCH PROFILE =================
  Future<void> _fetchProfile() async {
    try {

      final response =
          await dio.get("$baseurl/api/worker/profile/$profileId");

      final data = response.data;
print(data);
      _nameController.text = data['name'] ?? "";
      _emailController.text = data['email'] ?? "";
      _phoneController.text =
          data['phone_number']?.toString() ?? "";
      _dobController.text = data['dob'] ?? "";
      _ageController.text =
          data['age']?.toString() ?? "";
      _wageController.text =
          data['wage']?.toString() ?? "";
      _uniqueIdController.text =
          data['uniqueid'] ?? "";

      _selectedSkills =
          List<String>.from(data['skills'] ?? []);

      _isAvailable = data['isAvailable'] ?? true;

      _networkImage = data['photo'];

      setState(() => _isLoading = false);

    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error loading profile")),
        );
      }
    }
  }

  // ================= IMAGE PICK =================
  Future<void> _pickImage() async {
    if (!_isEditMode) return;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    _pickedFile = image;
    _imageBytes = await image.readAsBytes();

    setState(() {});
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile Updated Successfully")),
          );
        }

        _isEditMode = false;
        await _fetchProfile();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Update Failed")),
        );
      }
    }

    setState(() => _isUpdating = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Worker Profile"),
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditMode) {
                _updateProfile();
              } else {
                setState(() => _isEditMode = true);
              }
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    // ===== Profile Image =====
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _imageBytes != null
                            ? MemoryImage(_imageBytes!)
                            : _networkImage != null
                                ? NetworkImage("$baseurl/${_networkImage!}")
                                : null,
                        child: (_imageBytes == null &&
                                _networkImage == null)
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                    ),

                    const SizedBox(height: 25),

                    _buildField(_nameController, "Name"),
                    _buildField(_emailController, "Email", readOnly: true),
                    _buildField(_phoneController, "Phone"),
                    _buildField(_dobController, "Date of Birth", readOnly: true),
                    _buildField(_ageController, "Age", readOnly: true),
                    _buildField(_uniqueIdController, "Unique ID", readOnly: true),
                    _buildField(_wageController, "Wage"),

                    const SizedBox(height: 20),

                    // ===== Availability Switch =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Available for Work",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: _isAvailable,
                          onChanged: _isEditMode
                              ? (val) {
                                  setState(() => _isAvailable = val);
                                }
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ===== Skills =====
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Select Skills",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allSkills.map((skill) {
                        final selected =
                            _selectedSkills.contains(skill);

                        return FilterChip(
                          label: Text(skill),
                          selected: selected,
                          selectedColor: Colors.green,
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.black,
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

                    const SizedBox(height: 30),

                    if (_isUpdating)
                      const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField(
      TextEditingController controller,
      String label,
      {bool readOnly = false}) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly || !_isEditMode,
        validator: (v) =>
            v == null || v.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
