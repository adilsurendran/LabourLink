import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:labourlink/login.dart';
import 'package:labourlink/worker/Register_worker.dart';
import 'package:labourlink/worker/homepage2.dart';

class WorkerJobsPage extends StatefulWidget {
  const WorkerJobsPage({super.key});

  @override
  State<WorkerJobsPage> createState() => _WorkerJobsPageState();
}

class _WorkerJobsPageState extends State<WorkerJobsPage>
    with SingleTickerProviderStateMixin {
  final Dio dio = Dio();
  final TextEditingController _searchController = TextEditingController();

  List allJobs = [];
  List filteredJobs = [];
  bool isLoading = true;
  DateTime? selectedDate;

  late double workerLat;
  late double workerLng;

  final Color _primaryColor = const Color(0xFF4A00E0);
  final Color _secondaryColor = const Color(0xFF8E2DE2);
  final Color _bgColor = const Color(0xFFF8FAFF);

  @override
  void initState() {
    super.initState();
    workerLat = _safeParse(latt);
    workerLng = _safeParse(lngg);
    fetchJobs();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================= SAFE PARSE =================

  double _safeParse(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // ================= DISTANCE =================

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

  double _deg2rad(double deg) {
    return deg * (pi / 180);
  }

  // ================= FILTERS =================

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredJobs = allJobs.where((job) {
        bool matchesSearch =
            (job["title"] ?? "").toLowerCase().contains(query) ||
            (job["profileId"]?["place"] ?? "").toLowerCase().contains(query);

        bool matchesDate = true;
        if (selectedDate != null) {
          DateTime jobDate = DateTime.parse(job["date"]);
          matchesDate =
              jobDate.year == selectedDate!.year &&
              jobDate.month == selectedDate!.month &&
              jobDate.day == selectedDate!.day;
        }

        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      selectedDate = null;
      filteredJobs = allJobs;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _applyFilters();
    }
  }

  // ================= FETCH JOBS =================

  Future<void> fetchJobs() async {
    try {
      setState(() => isLoading = true);
      final res = await dio.get("$baseurl/api/worker/pending-jobs");
      List data = res.data["data"];

      for (var job in data) {
        double userLat = _safeParse(job["profileId"]?["location"]?["lat"]);
        double userLng = _safeParse(job["profileId"]?["location"]?["lng"]);
        job["distance"] = _calculateDistance(
          workerLat,
          workerLng,
          userLat,
          userLng,
        );
      }

      data.sort((a, b) => a["distance"].compareTo(b["distance"]));

      setState(() {
        allJobs = data;
        filteredJobs = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ================= REQUEST JOB =================

  Future<void> requestJob(String workId) async {
    try {
      final res = await dio.post(
        "$baseurl/api/worker/request-job",
        data: {"workId": workId, "workerId": ProfileId},
      );

      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Request submitted successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        fetchJobs();
      }
    } on DioException catch (e) {
      String message = "Something went wrong";
      if (e.response != null) {
        final status = e.response?.statusCode;
        if (status == 400) {
          message = e.response?.data["message"] ?? "Invalid request";
        } else if (status == 404) {
          message = "Job not found";
        } else if (status == 500) {
          message = "Server error. Try again.";
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Unexpected error occurred"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          "Available Work",
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
          if (selectedDate != null)
            IconButton(
              icon: Icon(Icons.filter_list_off_rounded, color: _primaryColor),
              onPressed: _clearFilters,
              tooltip: "Clear Date Filter",
            ),
          IconButton(
            icon: Icon(
              Icons.calendar_month_rounded,
              color: selectedDate != null ? _primaryColor : Colors.black87,
            ),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Search job or location...",
                  prefixIcon: Icon(Icons.search_rounded, color: _primaryColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),

          // Date Filter Chip
          if (selectedDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  label: Text(
                    "Date: ${DateFormat('dd MMM yyyy').format(selectedDate!)}",
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onDeleted: _clearFilters,
                  deleteIconColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ).animate().scale(alignment: Alignment.centerLeft),

          // Jobs List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: _primaryColor))
                : RefreshIndicator(
                    onRefresh: fetchJobs,
                    color: _primaryColor,
                    child: filteredJobs.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredJobs.length,
                            itemBuilder: (context, index) {
                              final job = filteredJobs[index];
                              return _buildJobCard(job, index);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 400,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No jobs found matching your criteria",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _clearFilters,
              child: Text(
                "Clear all filters",
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(Map job, int index) {
    return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: Colors.transparent,
              child: ExpansionTile(
                tilePadding: const EdgeInsets.all(20),
                backgroundColor: Colors.white,
                collapsedBackgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${job["distance"].toStringAsFixed(1)} km away",
                            style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat(
                            'dd MMM',
                          ).format(DateTime.parse(job["date"])),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      job["title"] ?? "Untitled Job",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: _primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          job["profileId"]?["place"] ?? "Unknown place",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          "Job Description",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          job["description"] ?? "No description provided.",
                          style: TextStyle(
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: _primaryColor.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                size: 16,
                                color: _primaryColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              job["profileId"]?["name"] ?? "Unknown User",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () => requestJob(job["_id"]),
                            child: const Text(
                              "Submit Interest",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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
        )
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: 500.ms)
        .slideY(begin: 0.1, end: 0);
  }
}
