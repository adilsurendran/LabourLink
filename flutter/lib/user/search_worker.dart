import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:labourlink/login.dart';
import 'package:labourlink/user/homepage.dart';
import 'package:labourlink/user/myrequesttoworker.dart';
import 'package:labourlink/worker/Register_worker.dart';

class Worker {
  final String id;
  final String name;
  final List<String> skills;
  final String imageUrl;
  final double wage;
  final bool isAvailable;
  final double lat;
  final double lng;
  final double avgRating;
  double distance;

  Worker({
    required this.id,
    required this.name,
    required this.skills,
    required this.imageUrl,
    required this.wage,
    required this.isAvailable,
    required this.lat,
    required this.lng,
    required this.avgRating,
    this.distance = 0,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json["_id"],
      name: json["name"] ?? "",
      skills: json["skills"] != null ? List<String>.from(json["skills"]) : [],
      imageUrl: json["photo"] != null ? "$baseurl/${json["photo"]}" : "",
      wage: (json["wage"] ?? 0).toDouble(),
      isAvailable: json["isAvailable"] ?? false,
      lat: _parseDouble(json["location"]?["lat"]),
      lng: _parseDouble(json["location"]?["lng"]),
      avgRating: (json["avgRating"] ?? 0).toDouble(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class SearchWorkerPage extends StatefulWidget {
  const SearchWorkerPage({super.key});

  @override
  State<SearchWorkerPage> createState() => _SearchWorkerPageState();
}

class _SearchWorkerPageState extends State<SearchWorkerPage> {
  final Dio dio = Dio();
  final TextEditingController _searchController = TextEditingController();

  List<Worker> _workers = [];
  List<Worker> _filteredWorkers = [];

  String _selectedCategory = "All";
  String _selectedWageFilter = "All";
  String _selectedRatingFilter = "All";

  final List<String> _categories = [
    "All",
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

  late double userLat;
  late double userLng;

  final Color _primaryColor = const Color(0xFF4A00E0);
  final Color _secondaryColor = const Color(0xFF8E2DE2);

  @override
  void initState() {
    super.initState();
    userLat = double.tryParse(lat) ?? 0.0;
    userLng = double.tryParse(lng) ?? 0.0;
    _fetchWorkers();
    _searchController.addListener(filterWorkers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================= DISTANCE CALCULATION =================

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371;
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  // ================= FETCH WORKERS =================

  Future<void> _fetchWorkers() async {
    try {
      final response = await dio.get("$baseurl/api/worker/available");
      final List data = response.data;

      List<Worker> workers = data.map((json) => Worker.fromJson(json)).toList();

      for (var w in workers) {
        w.distance = _calculateDistance(userLat, userLng, w.lat, w.lng);
      }

      workers.sort((a, b) => a.distance.compareTo(b.distance));

      setState(() {
        _workers = workers;
        _filteredWorkers = workers;
      });
    } catch (e) {
      debugPrint("Fetch error: $e");
    }
  }

  // ================= FILTER LOGIC =================

  void filterWorkers() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredWorkers = _workers.where((worker) {
        final matchesSearch =
            worker.name.toLowerCase().contains(query) ||
            worker.skills.any((skill) => skill.toLowerCase().contains(query));

        final matchesCategory =
            _selectedCategory == "All" ||
            worker.skills.contains(_selectedCategory);

        bool matchesWage = true;
        switch (_selectedWageFilter) {
          case "200":
            matchesWage = worker.wage <= 200;
            break;
          case "300":
            matchesWage = worker.wage <= 300;
            break;
          case "500":
            matchesWage = worker.wage <= 500;
            break;
          case "999":
            matchesWage = worker.wage <= 999;
            break;
          case "1000+":
            matchesWage = worker.wage >= 1000;
            break;
        }

        bool matchesRating = true;
        switch (_selectedRatingFilter) {
          case "3":
            matchesRating = worker.avgRating >= 3;
            break;
          case "4":
            matchesRating = worker.avgRating >= 4;
            break;
        }

        return matchesSearch && matchesCategory && matchesWage && matchesRating;
      }).toList();
    });
  }

  // ================= REQUEST MODAL =================

  void _openRequestModal(Worker worker) {
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final jobTypeController = TextEditingController();
    final descController = TextEditingController();
    final placeController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Request ${worker.name}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildModalField(
                          "Job Type",
                          jobTypeController,
                          Icons.work_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildModalField(
                          "Place",
                          placeController,
                          Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModalField(
                                "Date",
                                dateController,
                                Icons.calendar_month_outlined,
                                readOnly: true,
                                onTap: () async {
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    dateController.text = DateFormat(
                                      "yyyy-MM-dd",
                                    ).format(picked);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModalField(
                                "Start Time",
                                timeController,
                                Icons.access_time,
                                readOnly: true,
                                onTap: () async {
                                  TimeOfDay? picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    timeController.text = picked.format(
                                      context,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildModalField(
                          "Description",
                          descController,
                          Icons.description_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 14,
                                ),
                              ),
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      setModalState(() => isSubmitting = true);
                                      try {
                                        await dio.post(
                                          "$baseurl/api/user/create",
                                          data: {
                                            "workerId": worker.id,
                                            "userId": ProfileId,
                                            "date": dateController.text,
                                            "startTime": timeController.text,
                                            "jobType": jobTypeController.text,
                                            "description": descController.text,
                                            "place": placeController.text,
                                          },
                                        );
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const UserRequestPage(),
                                            ),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Request sent successfully!",
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setModalState(
                                          () => isSubmitting = false,
                                        );
                                      }
                                    },
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "SUBMIT",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white30, size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.white24),
            ),
          ),
        ),
      ],
    );
  }

  // ================= UI BUILDERS =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Find Experts",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: Stack(children: [_buildBackground(), _buildContent()]),
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
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: _buildDecorativeShape(250, Colors.white.withOpacity(0.08)),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _buildDecorativeShape(300, Colors.white.withOpacity(0.05)),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeShape(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: Column(
        children: [
          _buildSearchAndCategories(),
          Expanded(
            child: _filteredWorkers.isEmpty
                ? _buildEmptyState()
                : _buildWorkersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndCategories() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search name or profession...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white70,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _categories
                  .map((cat) => _buildCategoryChip(cat))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final bool isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
        filterWorkers();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? Colors.white : Colors.white10),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? _primaryColor : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_rounded,
            color: Colors.white.withOpacity(0.2),
            size: 100,
          ),
          const SizedBox(height: 16),
          const Text(
            "No workers found",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildWorkersList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredWorkers.length,
      itemBuilder: (context, index) {
        return _buildWorkerCard(_filteredWorkers[index], index);
      },
    );
  }

  Widget _buildWorkerCard(Worker worker, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                _buildAvatar(worker),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        worker.skills.join(", "),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildMiniBadge(
                            Icons.star,
                            Colors.amber,
                            worker.avgRating.toStringAsFixed(1),
                          ),
                          const SizedBox(width: 12),
                          _buildMiniBadge(
                            Icons.location_on,
                            Colors.blueAccent,
                            "${worker.distance.toStringAsFixed(1)}km",
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "₹${worker.wage.toInt()}/hr",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRequestButton(worker),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.1);
  }

  Widget _buildAvatar(Worker worker) {
    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        image: worker.imageUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(worker.imageUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: worker.imageUrl.isEmpty
          ? const Icon(Icons.person, color: Colors.white30, size: 40)
          : null,
    );
  }

  Widget _buildMiniBadge(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestButton(Worker worker) {
    return ElevatedButton(
      onPressed: () => _openRequestModal(worker),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        "Request",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  // ================= FILTER SHEET =================

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              border: Border.all(color: Colors.white10),
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Center(
                        child: Text(
                          "Filter Options",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildFilterTitle("Wage Range"),
                      const SizedBox(height: 10),
                      _buildFilterOptions(
                        ["All", "200", "300", "500", "999", "1000+"],
                        [
                          "Any",
                          "₹200 or less",
                          "₹300 or less",
                          "₹500 or less",
                          "₹999 or less",
                          "₹1000 and above",
                        ],
                        _selectedWageFilter,
                        (val) {
                          setState(() => _selectedWageFilter = val!);
                          setModalState(() {});
                          filterWorkers();
                        },
                      ),
                      const SizedBox(height: 30),
                      _buildFilterTitle("Minimum Rating"),
                      const SizedBox(height: 10),
                      _buildFilterOptions(
                        ["All", "3", "4"],
                        ["Full Results", "3+ Stars", "4+ Stars"],
                        _selectedRatingFilter,
                        (val) {
                          setState(() => _selectedRatingFilter = val!);
                          setModalState(() {});
                          filterWorkers();
                        },
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "APPLY FILTERS",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFilterOptions(
    List<String> values,
    List<String> labels,
    String groupValue,
    Function(String?) onChanged,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(values.length, (index) {
        final bool isSelected = groupValue == values[index];
        return GestureDetector(
          onTap: () => onChanged(values[index]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white10,
              ),
            ),
            child: Text(
              labels[index],
              style: TextStyle(
                color: isSelected ? _primaryColor : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}
