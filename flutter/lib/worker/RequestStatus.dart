import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:labourlink/login.dart';
import 'package:labourlink/worker/Register_worker.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  final Dio dio = Dio();
  List allRequests = [];
  List filteredRequests = [];
  bool isLoading = true;
  String selectedStatus = "all";

  final Color _primaryColor = const Color(0xFF4A00E0);
  final Color _secondaryColor = const Color(0xFF8E2DE2);
  final Color _bgColor = const Color(0xFFF8FAFF);

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  // ================= FETCH =================

  Future<void> fetchRequests() async {
    try {
      setState(() => isLoading = true);

      final res = await dio.get(
        "$baseurl/api/worker/worker-requests/$ProfileId",
      );

      setState(() {
        allRequests = res.data["data"];
        _applyFilter(selectedStatus);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ================= FILTER =================

  void _applyFilter(String status) {
    setState(() {
      selectedStatus = status;
      if (status == "all") {
        filteredRequests = allRequests;
      } else {
        filteredRequests = allRequests
            .where(
              (req) =>
                  req["status"].toString().toLowerCase() ==
                  status.toLowerCase(),
            )
            .toList();
      }
    });
  }

  void _resetFilter() {
    _applyFilter("all");
  }

  // ================= CANCEL =================

  Future<void> cancelRequest(String requestId) async {
    try {
      await dio.delete("$baseurl/api/worker/cancel-request/$requestId");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Request Cancelled"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      fetchRequests();
    } on DioException catch (e) {
      String message = "Something went wrong";
      if (e.response != null) {
        message = e.response?.data["message"] ?? message;
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
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          "My Job Requests",
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
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            onPressed: fetchRequests,
          ),
          if (selectedStatus != "all")
            IconButton(
              icon: Icon(Icons.filter_list_off_rounded, color: _primaryColor),
              onPressed: _resetFilter,
              tooltip: "Reset Filter",
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterBar(),

          // Requests List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: _primaryColor))
                : RefreshIndicator(
                    onRefresh: fetchRequests,
                    color: _primaryColor,
                    child: filteredRequests.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredRequests.length,
                            itemBuilder: (context, index) {
                              final req = filteredRequests[index];
                              return _buildRequestCard(req, index);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final statusOptions = [
      "all",
      "pending",
      "accepted",
      "rejected",
      "completed",
    ];

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: statusOptions.length,
        itemBuilder: (context, index) {
          final status = statusOptions[index];
          final isSelected = selectedStatus == status;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                status.substring(0, 1).toUpperCase() + status.substring(1),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (val) => _applyFilter(status),
              backgroundColor: Colors.white,
              selectedColor: _primaryColor,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? _primaryColor : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              elevation: isSelected ? 4 : 0,
              pressElevation: 8,
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.1, end: 0);
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
            Icon(
              Icons.assignment_late_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              "No requests found with status: ${selectedStatus.toUpperCase()}",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _resetFilter,
              child: Text(
                "Reset Filter",
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

  Widget _buildRequestCard(Map req, int index) {
    final work = req["workId"];
    final status = req["status"].toString().toLowerCase();

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case "accepted":
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case "rejected":
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      case "completed":
        statusColor = Colors.blue;
        statusIcon = Icons.verified_rounded;
        break;
      case "pending":
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_rounded;
    }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.05),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const Spacer(),
                        if (work?["date"] != null)
                          Text(
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(DateTime.parse(work["date"])),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Content Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          work?["title"] ?? "Untitled Job",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          work?["description"] ?? "No description provided.",
                          style: TextStyle(
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 18,
                              color: _primaryColor.withOpacity(0.7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              work?["profileId"]?["name"] ?? "Unknown User",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (status == "pending")
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmCancel(req["_id"]),
                              icon: const Icon(Icons.cancel_outlined, size: 20),
                              label: const Text("Cancel Request"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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

  void _confirmCancel(String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Request?"),
        content: const Text(
          "Are you sure you want to cancel this job request?",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No, Keep it"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              cancelRequest(requestId);
            },
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
