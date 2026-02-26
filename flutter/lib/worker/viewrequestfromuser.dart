import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:labourlink/login.dart';
import 'package:labourlink/worker/Register_worker.dart';

class WorkerRequestPage extends StatefulWidget {
  const WorkerRequestPage({super.key});

  @override
  State<WorkerRequestPage> createState() => _WorkerRequestPageState();
}

class _WorkerRequestPageState extends State<WorkerRequestPage> {
  final Dio dio = Dio();

  List allRequests = [];
  List filteredRequests = [];
  bool isLoading = true;
  String selectedStatus = "all";
  DateTime? selectedDate;

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
      final response = await dio.get(
        "$baseurl/api/worker/getrequest/$ProfileId",
      );

      setState(() {
        allRequests = response.data;
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  // ================= FILTERS =================

  void _applyFilters() {
    setState(() {
      filteredRequests = allRequests.where((req) {
        // Status Filter
        bool matchesStatus = true;
        if (selectedStatus != "all") {
          matchesStatus =
              req["status"].toString().toLowerCase() ==
              selectedStatus.toLowerCase();
        }

        // Date Filter
        bool matchesDate = true;
        if (selectedDate != null) {
          try {
            DateTime reqDate = DateTime.parse(req["date"]);
            matchesDate =
                reqDate.year == selectedDate!.year &&
                reqDate.month == selectedDate!.month &&
                reqDate.day == selectedDate!.day;
          } catch (e) {
            matchesDate = false;
          }
        }

        return matchesStatus && matchesDate;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      selectedStatus = "all";
      selectedDate = null;
      _applyFilters();
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

  // ================= UPDATE STATUS =================

  Future<void> updateStatus(String requestId, String status) async {
    try {
      final res = await dio.put(
        "$baseurl/api/worker/update-status/$requestId",
        data: {"status": status},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Request ${status.substring(0, 1).toUpperCase() + status.substring(1)}",
          ),
          backgroundColor: status == "accepted" ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      fetchRequests();
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update status"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "accepted":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "completed":
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          "Direct Requests",
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
              Icons.calendar_month_rounded,
              color: selectedDate != null ? _primaryColor : Colors.black87,
            ),
            onPressed: () => _selectDate(context),
          ),
          if (selectedStatus != "all" || selectedDate != null)
            IconButton(
              icon: Icon(Icons.filter_list_off_rounded, color: _primaryColor),
              onPressed: _resetFilters,
              tooltip: "Reset All Filters",
            ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter Bar
          _buildStatusFilter(),

          // Date Filter Chip (if active)
          if (selectedDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  label: Text(
                    "Date: ${DateFormat('dd MMM yyyy').format(selectedDate!)}",
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  onDeleted: () {
                    setState(() => selectedDate = null);
                    _applyFilters();
                  },
                  deleteIconColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ).animate().scale(alignment: Alignment.centerLeft),

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
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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

  Widget _buildStatusFilter() {
    final statusOptions = ["all", "pending", "rejected", "completed"];

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
              onSelected: (val) {
                setState(() => selectedStatus = status);
                _applyFilters();
              },
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
              Icons.mark_email_unread_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              "No requests found matching filters",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _resetFilters,
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

  Widget _buildRequestCard(Map req, int index) {
    final status = req["status"].toString().toLowerCase();
    final user = req["userId"];
    final statusColor = getStatusColor(status);

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
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.05),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: _primaryColor.withOpacity(0.1),
                          child: Text(
                            (user?["name"] ?? "U")
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?["name"] ?? "Unknown User",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                req["jobType"] ?? "General Task",
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          Icons.location_on_rounded,
                          req["place"] ?? "No location",
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildInfoRow(
                              Icons.calendar_today_rounded,
                              req["date"] ?? "No date",
                            ),
                            const SizedBox(width: 20),
                            _buildInfoRow(
                              Icons.access_time_rounded,
                              req["startTime"] ?? "No time",
                            ),
                          ],
                        ),
                        if (req["description"] != null &&
                            req["description"].toString().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            req["description"],
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Actions
                        if (status == "pending")
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () =>
                                      updateStatus(req["_id"], "accepted"),
                                  child: const Text(
                                    "Accept",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () =>
                                      updateStatus(req["_id"], "rejected"),
                                  child: const Text(
                                    "Reject",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
      ],
    );
  }
}
