import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:labourlink/login.dart';
import 'package:labourlink/worker/Register_worker.dart';

class UserComplaintsPage extends StatefulWidget {
  const UserComplaintsPage({super.key});

  @override
  State<UserComplaintsPage> createState() => _UserComplaintsPageState();
}

class _UserComplaintsPageState extends State<UserComplaintsPage> {
  final Dio dio = Dio();

  List complaints = [];
  List works = [];

  String selectedWorkId = "all";
  bool isLoading = true;

  final Color _primaryColor = const Color(0xFF4A00E0);
  final Color _secondaryColor = const Color(0xFF8E2DE2);

  @override
  void initState() {
    super.initState();
    fetchWorks();
    fetchComplaints();
  }

  // ================= FETCH WORKS =================

  Future<void> fetchWorks() async {
    try {
      final res = await dio.get("$baseurl/api/user/get-works/$ProfileId");
      if (mounted) {
        setState(() {
          works = res.data["data"] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Fetch works error: $e");
    }
  }

  // ================= FETCH COMPLAINTS =================

  Future<void> fetchComplaints({String? workId}) async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      String url = "$baseurl/api/user/get-reply/$ProfileId";
      if (workId != null && workId != "all") {
        url += "?workId=$workId";
      }

      final res = await dio.get(url);
      if (mounted) {
        setState(() {
          complaints = res.data["data"] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch complaints error: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "My Complaints",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
            right: -100,
            child: _buildDecorativeShape(300, Colors.white.withOpacity(0.08)),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _buildDecorativeShape(250, Colors.white.withOpacity(0.05)),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildWorkFilter(),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : complaints.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: complaints.length,
                      itemBuilder: (_, index) =>
                          _buildComplaintCard(complaints[index], index),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkFilter() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedWorkId,
              dropdownColor: const Color(0xFF1A1A1A).withOpacity(0.95),
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
              ),
              items: [
                const DropdownMenuItem(
                  value: "all",
                  child: Text(
                    "All Complaints",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ...works.map(
                  (w) => DropdownMenuItem(
                    value: w["_id"],
                    child: Text(
                      w["title"] ?? "Untitled Work",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedWorkId = value;
                  });
                  fetchComplaints(workId: selectedWorkId);
                }
              },
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mark_chat_read_outlined,
            color: Colors.white.withOpacity(0.2),
            size: 100,
          ),
          const SizedBox(height: 16),
          const Text(
            "No complaints found",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildComplaintCard(dynamic c, int index) {
    final status = c["status"] ?? "pending";
    final isResolved = status == "resolved";
    final statusColor = isResolved ? Colors.greenAccent : Colors.orangeAccent;

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
                    Expanded(
                      child: Text(
                        c["workId"]?["title"] ?? "General Complaint",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusBadge(status, statusColor),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "COMPLAINT",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c["complaint"] ?? "No description provided",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 20),
                const Text(
                  "ADMIN REPLY",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Text(
                    c["reply"] ?? "Awaiting response...",
                    style: TextStyle(
                      color: c["reply"] != null ? Colors.white : Colors.white24,
                      fontSize: 13,
                      fontStyle: c["reply"] != null
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat("dd MMM yyyy, hh:mm a").format(
                        DateTime.parse(
                          c["createdAt"] ?? DateTime.now().toString(),
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    if (isResolved)
                      const Icon(
                        Icons.verified_rounded,
                        color: Colors.greenAccent,
                        size: 18,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.1);
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
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
}
