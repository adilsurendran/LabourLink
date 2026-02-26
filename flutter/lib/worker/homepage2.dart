import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:labourlink/login.dart';
import 'package:labourlink/worker/Hiring.dart';
import 'package:labourlink/worker/Register_worker.dart';
import 'package:labourlink/worker/RequestStatus.dart';
import 'package:labourlink/worker/WorkerProfile.dart';
import 'package:dio/dio.dart';
import 'package:labourlink/worker/sendfeedback.dart';
import 'package:labourlink/worker/viewrequestfromuser.dart';
import 'package:labourlink/chat_bot_page.dart';

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({super.key});

  @override
  State<WorkerHomePage> createState() => _WorkerHomePageState();
}

String latt = "";
String lngg = "";

class _WorkerHomePageState extends State<WorkerHomePage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Dio dio = Dio();

  String? profileId;
  String name = "";
  String skill = "";
  String? photo;
  List jobs = [];
  bool isJobsLoading = true;

  late final AnimationController _controller;

  final Color _primaryColor = const Color(0xFF4A00E0);
  final Color _secondaryColor = const Color(0xFF8E2DE2);
  final Color _bgColor = const Color(0xFFF8FAFF);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileId = ProfileId;
      if (profileId != null) {
        _fetchProfile();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await dio.get("$baseurl/api/worker/profile/$ProfileId");
      final data = response.data;
      if (mounted) {
        setState(() {
          name = data["name"] ?? "";
          skill = (data["skills"] != null && data["skills"].isNotEmpty)
              ? data["skills"][0]
              : "";
          photo = data["photo"];
          latt = data["location"]["lat"].toString();
          lngg = data["location"]["lng"].toString();
        });
        _fetchJobs();
      }
    } catch (e) {
      debugPrint("Profile Fetch Error: $e");
    }
  }

  // ================= JOBS LOGIC =================

  double _safeParse(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

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

  Future<void> _fetchJobs() async {
    try {
      setState(() => isJobsLoading = true);
      final res = await dio.get("$baseurl/api/worker/pending-jobs");
      List data = res.data["data"];

      double workerLat = _safeParse(latt);
      double workerLng = _safeParse(lngg);

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

      if (mounted) {
        setState(() {
          // Only show top 6 jobs as requested
          jobs = data.take(6).toList();
          isJobsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isJobsLoading = false);
      debugPrint("Jobs Fetch Error: $e");
    }
  }

  ImageProvider? get userImage {
    if (photo != null && photo!.isNotEmpty) {
      return NetworkImage("$baseurl/$photo");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgColor,
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          // 1. Dynamic Background Decoration
          Positioned(
            top: -size.width * 0.2,
            right: -size.width * 0.1,
            child: _buildFloatingShape(
              size.width * 0.8,
              _primaryColor.withOpacity(0.05),
            ),
          ),
          Positioned(
            top: size.height * 0.4,
            left: -size.width * 0.2,
            child: _buildFloatingShape(
              size.width * 0.6,
              _secondaryColor.withOpacity(0.03),
            ),
          ),

          // 2. Main Scrollable Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Premium Custom AppBar
              SliverAppBar(
                expandedHeight: 220,
                collapsedHeight: 100,
                pinned: true,
                backgroundColor: Colors.white.withOpacity(0.8),
                elevation: 0,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    return FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, _bgColor],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildAnimatedItem(
                                  index: 0,
                                  child: Text(
                                    "Partner Dashboard",
                                    style: TextStyle(
                                      color: _primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildAnimatedItem(
                                  index: 1,
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "Hello, ",
                                          style: TextStyle(
                                            fontSize: 28,
                                            color: Colors.black.withOpacity(
                                              0.7,
                                            ),
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                        TextSpan(
                                          text: name.split(' ').first,
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                _buildAnimatedItem(
                                  index: 2,
                                  child: Text(
                                    skill.isNotEmpty ? skill : "Labour Partner",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      centerTitle: true,
                    );
                  },
                ),
                leading: IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    color: _primaryColor,
                    size: 28,
                  ),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.smart_toy_outlined,
                      color: _primaryColor,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatBotPage(),
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: CircleAvatar(
                        backgroundColor: _primaryColor.withOpacity(0.1),
                        backgroundImage: userImage,
                        child: userImage == null
                            ? Icon(Icons.person, color: _primaryColor)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),

              // Body Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Column(
                    children: [
                      // Section Header
                      _buildAnimatedItem(
                        index: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader(
                              "Available Jobs",
                              "Explore work near you",
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const WorkerJobsPage(),
                                  ),
                                );
                              },
                              child: Text(
                                "View All",
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Jobs List
                      _buildJobsSection(),

                      const SizedBox(height: 32),

                      // Show More Button
                      if (jobs.length >= 6)
                        _buildAnimatedItem(
                          index: 10,
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 20),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const WorkerJobsPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: BorderSide(
                                    color: _primaryColor.withOpacity(0.2),
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "SHOW MORE JOBS",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _buildAnimatedItem(
        index: 12,
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkerRequestPage()),
            );
          },
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 10,
          icon: const Icon(Icons.call_made_rounded),
          label: const Text(
            "DIRECT REQUESTS",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingShape(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }

  Widget _buildJobsSection() {
    if (isJobsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (jobs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(Icons.work_outline_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No jobs available right now",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return _buildAnimatedItem(index: index + 4, child: _buildJobCard(job));
      },
    );
  }

  Widget _buildJobCard(Map job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkerJobsPage()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        job["title"] ?? "Untitled Job",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${job["distance"]?.toStringAsFixed(1)} km",
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  job["description"] ?? "",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildJobDetail(
                      Icons.location_on_outlined,
                      job["profileId"]?["place"] ?? "Near you",
                    ),
                    const Spacer(),
                    _buildJobDetail(
                      Icons.calendar_today_outlined,
                      job["date"] != null
                          ? DateFormat(
                              'dd MMM',
                            ).format(DateTime.parse(job["date"]))
                          : "Today",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().shimmer(
      duration: 3.seconds,
      color: _primaryColor.withOpacity(0.03),
    );
  }

  Widget _buildJobDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _primaryColor.withOpacity(0.7)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 80,
              bottom: 40,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: userImage,
                  child: userImage == null
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  skill.isNotEmpty ? skill : "Verified Partner",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.home_outlined, "Home", () {
                  Navigator.pop(context);
                }, active: true),
                _buildDrawerItem(
                  Icons.work_outline_rounded,
                  "Available Jobs",
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WorkerJobsPage()),
                    );
                  },
                ),
                _buildDrawerItem(Icons.history_outlined, "Request Status", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyRequestsPage()),
                  );
                }),
                _buildDrawerItem(
                  Icons.person_outline_rounded,
                  "Direct Requests",
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkerRequestPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.star_outline_rounded,
                  "Send Feedback",
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SendFeedbackPageofWorker(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(Icons.person_pin_outlined, "My Profile", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                }),
              ],
            ),
          ),
          const Divider(),
          _buildDrawerItem(Icons.logout_rounded, "Logout", () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }, isLogout: true),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isLogout = false,
    bool active = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout
            ? Colors.redAccent
            : (active ? _primaryColor : Colors.grey[700]),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout
              ? Colors.redAccent
              : (active ? _primaryColor : Colors.black87),
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      selected: active,
      selectedTileColor: _primaryColor.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildAnimatedItem({required int index, required Widget child}) {
    final double startTime = (index * 0.1).clamp(0.0, 1.0);
    final double endTime = (startTime + 0.5).clamp(0.0, 1.0);

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startTime, endTime, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
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
