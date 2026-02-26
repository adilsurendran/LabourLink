import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:labourlink/login.dart';
import 'package:labourlink/user/homepage.dart';
import 'package:labourlink/worker/Register_worker.dart';

class JobRequestsPage extends StatefulWidget {
  final String workId;

  const JobRequestsPage({super.key, required this.workId});

  @override
  State<JobRequestsPage> createState() => _JobRequestsPageState();
}

class _JobRequestsPageState extends State<JobRequestsPage> {
  final Dio dio = Dio();

  List requests = [];
  List filtered = [];

  String statusFilter = "All";
  String wageFilter = "All";
  String ratingFilter = "All";

  late double userLat;
  late double userLng;

  final Color _primaryColor = const Color(0xFF4A00E0);
  final Color _secondaryColor = const Color(0xFF8E2DE2);

  @override
  void initState() {
    super.initState();
    userLat = _safeParse(lat);
    userLng = _safeParse(lng);
    fetchRequests();
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

  double _deg2rad(double deg) => deg * (pi / 180);

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  // ================= FETCH =================

  Future<void> fetchRequests() async {
    try {
      final res = await dio.get(
        "$baseurl/api/user/job-requests/${widget.workId}",
      );
      List data = res.data["data"];

      for (var r in data) {
        final worker = r["workerId"];
        double wLat = _safeParse(worker["location"]?["lat"]);
        double wLng = _safeParse(worker["location"]?["lng"]);

        r["distance"] = calculateDistance(userLat, userLng, wLat, wLng);
      }

      setState(() {
        requests = data;
        applyFilters();
      });
    } catch (e) {
      debugPrint("Fetch requests error: $e");
    }
  }

  // ================= FILTER LOGIC =================

  void applyFilters() {
    setState(() {
      filtered = requests.where((r) {
        final worker = r["workerId"];
        final status = r["status"];
        final wage = _safeParse(worker["wage"]);
        final rating = _safeParse(worker["avgRating"]);

        bool statusMatch = statusFilter == "All" || status == statusFilter;

        bool wageMatch = true;
        switch (wageFilter) {
          case "200":
            wageMatch = wage <= 200;
            break;
          case "300":
            wageMatch = wage <= 300;
            break;
          case "500":
            wageMatch = wage <= 500;
            break;
          case "999":
            wageMatch = wage <= 999;
            break;
          case "1000+":
            wageMatch = wage >= 1000;
            break;
        }

        bool ratingMatch = true;
        switch (ratingFilter) {
          case "3":
            ratingMatch = rating >= 3;
            break;
          case "4":
            ratingMatch = rating >= 4;
            break;
        }

        return statusMatch && wageMatch && ratingMatch;
      }).toList();
    });
  }

  // ================= ACCEPT / REJECT =================

  Future<void> accept(String id) async {
    try {
      await dio.put("$baseurl/api/user/accept/$id");
      fetchRequests();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error accepting request")));
    }
  }

  Future<void> reject(String id) async {
    try {
      await dio.put("$baseurl/api/user/reject/$id");
      fetchRequests();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error rejecting request")));
    }
  }

  // ================= COMPLETE WORK =================

  Future<void> completeJobRequest(
    String id,
    double rating,
    String review,
  ) async {
    try {
      await dio.put(
        "$baseurl/api/user/complete-job-request/$id",
        data: {"rating": rating, "review": review},
      );
      fetchRequests();
    } catch (e) {
      debugPrint("Complete job request error: $e");
    }
  }

  void showRatingDialog(String requestId) {
    double selectedRating = 0;
    TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AlertDialog(
                backgroundColor: const Color(0xFF1A1A1A).withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: const BorderSide(color: Colors.white10),
                ),
                title: const Text(
                  "Rate Your Experience",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              selectedRating = index + 1.0;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reviewController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Write a review (optional)",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      if (selectedRating == 0) return;
                      completeJobRequest(
                        requestId,
                        selectedRating,
                        reviewController.text,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "SUBMIT",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================= COMPLAINT =================

  void openComplaintModal(String workerId) {
    final complaintController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A).withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: const BorderSide(color: Colors.white10),
            ),
            title: const Text(
              "Report Issue",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: complaintController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Describe the issue...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (complaintController.text.trim().isEmpty) return;
                        setModalState(() => isSubmitting = true);
                        try {
                          await dio.post(
                            "$baseurl/api/user/createComplaint",
                            data: {
                              "userId": ProfileId,
                              "workId": widget.workId,
                              "workerId": workerId,
                              "complaint": complaintController.text.trim(),
                            },
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Complaint submitted successfully",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isSubmitting = false);
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= FILTER SHEET =================

  void openFilterSheet() {
    String tempStatus = statusFilter;
    String tempWage = wageFilter;
    String tempRating = ratingFilter;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white10),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(
                    child: Text(
                      "Filter Requests",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildFilterTitle("Status"),
                  const SizedBox(height: 10),
                  _buildChipFilter(
                    ["All", "pending", "accepted", "completed", "rejected"],
                    tempStatus,
                    (val) => setModalState(() => tempStatus = val),
                  ),
                  const SizedBox(height: 24),
                  _buildFilterTitle("Max Wage"),
                  const SizedBox(height: 10),
                  _buildChipFilter(
                    ["All", "200", "300", "500", "999", "1000+"],
                    tempWage,
                    (val) => setModalState(() => tempWage = val),
                  ),
                  const SizedBox(height: 24),
                  _buildFilterTitle("Min Rating"),
                  const SizedBox(height: 10),
                  _buildChipFilter(
                    ["All", "3", "4"],
                    tempRating,
                    (val) => setModalState(() => tempRating = val),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setModalState(() {
                            tempStatus = "All";
                            tempWage = "All";
                            tempRating = "All";
                          }),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "Reset",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              statusFilter = tempStatus;
                              wageFilter = tempWage;
                              ratingFilter = tempRating;
                            });
                            applyFilters();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "Apply",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTitle(String title) => Text(
    title,
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 13,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _buildChipFilter(
    List<String> options,
    String current,
    Function(String) onSelect,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final bool isSelected = current == opt;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white10,
              ),
            ),
            child: Text(
              opt.toUpperCase(),
              style: TextStyle(
                color: isSelected ? _primaryColor : Colors.white,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Worker Requests",
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
            onPressed: openFilterSheet,
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
            child: _buildDecorativeShape(250, Colors.white.withOpacity(0.07)),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _buildDecorativeShape(300, Colors.white.withOpacity(0.04)),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeShape(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _buildContent() {
    return SafeArea(
      child: filtered.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              physics: const BouncingScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _buildRequestCard(filtered[i], i),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_ind_outlined,
            color: Colors.white.withOpacity(0.2),
            size: 100,
          ),
          const SizedBox(height: 16),
          const Text(
            "No requests found",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildRequestCard(dynamic r, int index) {
    final worker = r["workerId"];
    final status = r["status"];

    Color statusColor = Colors.orange;
    if (status == "accepted") statusColor = Colors.green;
    if (status == "completed") statusColor = Colors.blueAccent;
    if (status == "rejected") statusColor = Colors.red;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      worker["name"] ?? "Unknown",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildStatusBadge(status, statusColor),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoBadge(
                      Icons.currency_rupee_rounded,
                      "₹${worker["wage"]}/hr",
                    ),
                    const SizedBox(width: 12),
                    _buildInfoBadge(
                      Icons.star_rounded,
                      "${worker["avgRating"]}",
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoBadge(
                  Icons.location_on_rounded,
                  "${r["distance"].toStringAsFixed(1)} km away",
                ),
                const SizedBox(height: 20),
                if (status == "pending")
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          "Accept",
                          Colors.green,
                          () => accept(r["_id"]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          "Reject",
                          Colors.redAccent,
                          () => reject(r["_id"]),
                        ),
                      ),
                    ],
                  ),
                if (status == "accepted")
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          "Report Issue",
                          Colors.orangeAccent,
                          () => openComplaintModal(worker["_id"]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          "Completed?",
                          Colors.blueAccent,
                          () => showRatingDialog(r["_id"]),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.1);
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.8),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white10),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
