import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:labourlink/login.dart';
import 'package:labourlink/worker/Hiring.dart';
import 'package:labourlink/worker/Register_worker.dart';
import 'package:labourlink/worker/RequestStatus.dart';
import 'package:labourlink/worker/WorkerProfile.dart';
import 'package:dio/dio.dart';
import 'package:labourlink/worker/sendfeedback.dart';
import 'package:labourlink/worker/viewrequestfromuser.dart';

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({super.key});

  @override
  State<WorkerHomePage> createState() => _WorkerHomePageState();
}
  String latt ="";
  String lngg ="";

class _WorkerHomePageState extends State<WorkerHomePage> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Dio dio = Dio();

  String? profileId;
  String name = "";
  String skill = "";
  String? photo;


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileId = ProfileId;

      if (profileId == null) {
        debugPrint("ProfileId is NULL");
        return;
      }

      _fetchProfile();
    });
  }

  Future<void> _fetchProfile() async {
    try {

      final response =
          await dio.get("$baseurl/api/worker/profile/$ProfileId");

      final data = response.data;
      setState(() {
        name = data["name"] ?? "";
        skill = (data["skills"] != null && data["skills"].isNotEmpty)
            ? data["skills"][0]
            : "";
        photo = data["photo"];
        latt = data["location"]["lat"];
        lngg = data["location"]["lng"];
              // print("lat"+lat+"lng"+lng);

        
      });

    } catch (e) {
      print(e);
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
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: _buildDrawer(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            collapsedHeight: 90,
            pinned: true,
            floating: true,
            backgroundColor: const Color(0xFF059669),
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.inbox_rounded, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InboxPage()),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: userImage,
                      child: userImage == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Welcome back!",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader("Available Jobs", "Find nearby work"),
                  const SizedBox(height: 16),
                  _buildJobList(),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF059669),
        icon: const Icon(Icons.search, color: Colors.white),
        label: const Text("Find Jobs"),
      ).animate(delay: 300.ms).slideY(begin: 1, end: 0),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            color: const Color(0xFF059669),
            child: Column(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 44,
                      backgroundImage: userImage,
                      child: userImage == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  skill,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.work),
            title: const Text("My Jobs"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyJobsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text("View Request(from user)"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkerRequestPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text("Jobs Available"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkerJobsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_history),
            title: const Text("Request Status"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyRequestsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_history),
            title: const Text("Send a Review"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SendFeedbackPageofWorker()),
              );
            },
          ),
          const Spacer(),
          ListTile(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (route) => false,
              );
            },
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildJobList() {
    return const SizedBox(); // removed dummy job cards
  }
}

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inbox"),
        backgroundColor: const Color(0xFF059669),
      ),
      body: const Center(child: Text("Inbox Page")),
    );
  }
}

class MyJobsPage extends StatelessWidget {
  const MyJobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Jobs")),
      body: const Center(child: Text("My Jobs Page")),
    );
  }
}

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Schedule")),
      body: const Center(child: Text("Schedule Page")),
    );
  }
}