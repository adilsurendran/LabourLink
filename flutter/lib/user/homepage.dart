import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:labourlink/login.dart';
import 'package:dio/dio.dart';
import 'package:labourlink/user/complaint_user.dart';
import 'package:labourlink/user/myrequesttoworker.dart';
import 'package:labourlink/user/search_worker.dart';
import 'package:labourlink/user/sendfeedback.dart';
import 'package:labourlink/user/view_added_work_details.dart';
import 'package:labourlink/user/work_details_user.dart';
import 'package:labourlink/worker/Register_worker.dart';
import 'package:labourlink/user/profile_user.dart';
import 'package:labourlink/user/worker_profile.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

String lat = "";
String lng = "";

class _CustomerHomePageState extends State<CustomerHomePage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Dio _dio = Dio();

  String name = "";
  String? photo;
  int totalJobPosts = 0;
  int totalRequests = 0;

  late final AnimationController _controller;

  final Color _primaryColor = const Color(0xFF4A00E0);
  final Color _secondaryColor = const Color(0xFF8E2DE2);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _controller.forward();
    _fetchData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      // Parallel fetching for better performance
      await Future.wait([_fetchCustomerProfile(), _fetchDashboardStats()]);
    } catch (e) {
      debugPrint("Fetch Data Error: $e");
    }
  }

  Future<void> _fetchCustomerProfile() async {
    try {
      final response = await _dio.get("$baseurl/api/user/$ProfileId");
      final data = response.data;
      if (mounted) {
        setState(() {
          name = data["name"] ?? "User";
          photo = data["photo"];
          lat = data["location"]["lat"].toString();
          lng = data["location"]["lng"].toString();
        });
      }
    } catch (e) {
      debugPrint("Profile Fetch Error: $e");
    }
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final response = await _dio.get("$baseurl/api/user/stats/$ProfileId");
      if (response.data["success"]) {
        final stats = response.data["data"];
        if (mounted) {
          setState(() {
            totalJobPosts = stats["totalJobPosts"] ?? 0;
            totalRequests = stats["totalRequests"] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Stats Fetch Error: $e");
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
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          // 1. Dynamic Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_secondaryColor, _primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Floating Shapes for visual premium feel
          Positioned(
            top: -50,
            right: -50,
            child: _buildFloatingShape(
              size.width * 0.5,
              Colors.white.withOpacity(0.1),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: _buildFloatingShape(
              size.width * 0.7,
              Colors.white.withOpacity(0.05),
            ),
          ),

          // 2. Main Scrollable Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Premium Custom AppBar
              SliverAppBar(
                expandedHeight: 200,
                collapsedHeight: 100,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                actions: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserProfilePage(),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: userImage,
                        child: userImage == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAnimatedItem(
                            index: 0,
                            child: Text(
                              "Welcome back,",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          _buildAnimatedItem(
                            index: 1,
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Body Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Column(
                    children: [
                      // Stats Section
                      _buildAnimatedItem(
                        index: 2,
                        child: _buildGlassStatsSection(),
                      ),
                      const SizedBox(height: 32),

                      // Section Header
                      _buildAnimatedItem(
                        index: 3,
                        child: _buildSectionHeader(
                          "Quick Services",
                          "What do you need today?",
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Services Grid
                      _buildServicesGrid(),
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
              MaterialPageRoute(builder: (_) => const WorkDetailsUser()),
            ).then((_) => _fetchDashboardStats());
          },
          backgroundColor: Colors.white,
          foregroundColor: _primaryColor,
          elevation: 10,
          icon: const Icon(Icons.add_task_rounded, weight: 700),
          label: const Text(
            "POST NEW JOB",
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

  Widget _buildGlassStatsSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              _buildStatItem(
                Icons.work_history_rounded,
                totalJobPosts,
                "Job Posts",
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              _buildStatItem(
                Icons.handshake_rounded,
                totalRequests,
                "Direct Requests",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
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
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildServicesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.5,
      children: [
        _buildServiceCard(
          4,
          Icons.add_circle_outline_rounded,
          "Post New Work",
          "Add job requirements",
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkDetailsUser()),
            ).then((_) => _fetchDashboardStats());
          },
        ),
        _buildServiceCard(
          5,
          Icons.format_list_bulleted_rounded,
          "Manage My Jobs",
          "Edit or delete works",
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ViewWorksPage()),
            ).then((_) => _fetchDashboardStats());
          },
        ),
        _buildServiceCard(
          6,
          Icons.person_search_rounded,
          "Find Workers",
          "Search by category",
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchWorkerPage()),
            );
          },
        ),
        _buildServiceCard(
          7,
          Icons.history_edu_rounded,
          "Track Requests",
          "Check request status",
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserRequestPage()),
            ).then((_) => _fetchDashboardStats());
          },
        ),
        _buildServiceCard(
          8,
          Icons.feedback_outlined,
          "Complaints",
          "View admin replies",
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserComplaintsPage()),
            );
          },
        ),
        _buildServiceCard(
          9,
          Icons.rate_review_outlined,
          "Send Feedback",
          "Rate the experience",
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SendFeedbackPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(
    int index,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return _buildAnimatedItem(
      index: index,
      child:
          Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onTap,
                    child: Stack(
                      children: [
                        Positioned(
                          top: -10,
                          right: -10,
                          child: Icon(
                            icon,
                            size: 80,
                            color: _primaryColor.withOpacity(0.04),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  icon,
                                  color: _primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .shimmer(
                duration: 3.seconds,
                color: _primaryColor.withOpacity(0.05),
              ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_secondaryColor, _primaryColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white24,
              backgroundImage: userImage,
              child: userImage == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildDrawerItem(
                      Icons.dashboard_rounded,
                      "Dashboard",
                      () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      Icons.add_circle_outline_rounded,
                      "Post New Work",
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkDetailsUser(),
                          ),
                        ).then((_) => _fetchDashboardStats());
                      },
                    ),
                    _buildDrawerItem(
                      Icons.format_list_bulleted_rounded,
                      "Manage My Jobs",
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ViewWorksPage(),
                          ),
                        ).then((_) => _fetchDashboardStats());
                      },
                    ),
                    _buildDrawerItem(
                      Icons.person_search_rounded,
                      "Find Workers",
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SearchWorkerPage(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.history_edu_rounded,
                      "Track Requests",
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserRequestPage(),
                          ),
                        ).then((_) => _fetchDashboardStats());
                      },
                    ),
                    _buildDrawerItem(Icons.feedback_outlined, "Complaints", () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserComplaintsPage(),
                        ),
                      );
                    }),
                    _buildDrawerItem(
                      Icons.rate_review_outlined,
                      "Send Feedback",
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SendFeedbackPage(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.person_pin_rounded,
                      "My Profile",
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserProfilePage(),
                          ),
                        ).then((_) => _fetchData());
                      },
                    ),
                  ],
                ),
              ),
            ),
            _buildDrawerItem(Icons.logout_rounded, "Logout", () {
              ProfileId = null;
              Role = null;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            }, isLogout: true),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.redAccent.shade100 : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.redAccent.shade100 : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
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
