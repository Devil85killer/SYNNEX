import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/socket_service.dart';
import '../../main.dart'; // ✅ Global 'socket' and 'connectSocket' access

// ALUMNI PAGES
import 'alumni_profile.dart';
import 'alumni_post_job.dart';
import 'alumni_my_jobs.dart';
import 'alumni_chat_list.dart';

// ✅ COMMON JOB FEED
import 'package:synnex/screens/jobs/common_job_feed_page.dart';

class AlumniDashboard extends StatefulWidget {
  const AlumniDashboard({super.key});

  @override
  State<AlumniDashboard> createState() => _AlumniDashboardState();
}

class _AlumniDashboardState extends State<AlumniDashboard> {
  int _index = 0;

  /// ✅ PAGES
  final List<Widget> _pages = const [
    AlumniHomePage(),
    AlumniProfilePage(),
    AlumniPostJobPage(),
    AlumniMyJobsPage(),
    CommonJobFeedPage(),
    AlumniChatListPage(),
  ];

  final List<String> _titles = [
    "Dashboard",
    "Profile",
    "Post Job",
    "My Job Posts",
    "Job Feed",
    "Chats",
  ];

  @override
  void initState() {
    super.initState();
    // 🔥 Dashboard load hote hi socket sync karo
    _checkSocket();
  }

  /// 🔌 SMART RECONNECT & FORCE SETUP FOR ALUMNI
  Future<void> _checkSocket() async {
    print("🔄 Alumni Dashboard: Syncing Online Status...");
    
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // 1. Fetch Alumni Data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('alumni_users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          final jwt = data['chatifyJwt'];
          final myMongoId = data['chatifyUserId'];

          if (jwt != null && myMongoId != null) {
            // 2. Connection start karo
            connectSocket(jwt, myMongoId); 
            
            // 3. 🔥 FORCE ONLINE SIGNAL (Setup Event)
            // Humein server ko batana padega ki Alumni online aa gaya hai
            if (socket != null) {
               if (socket!.connected) {
                  socket!.emit("setup", myMongoId);
                  print("🚀 Alumni Setup Sent: $myMongoId");
               } else {
                  // Connection bante hi setup bhej do
                  socket!.on('connect', (_) {
                    socket!.emit("setup", myMongoId);
                    print("🚀 Alumni Handshake Complete: $myMongoId");
                  });
               }
            }
          }
        }
      }
    } catch (e) {
      print("❌ Alumni Dashboard Reconnect Error: $e");
    }
  }

  /// 🚪 LOGOUT
  Future<void> _logout() async {
    SocketService().disconnect(); 
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/alumni_login',
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),
      body: Row(
        children: [
          /// 1. NavigationRail
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) {
              setState(() => _index = i);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text("Dashboard"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person),
                label: Text("Profile"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.post_add),
                label: Text("Post Job"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.work),
                label: Text("My Job Posts"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.public),
                label: Text("Job Feed"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat),
                label: Text("Chats"),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          
          /// 2. Main Content Area
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: _pages[_index],
            ),
          ),
        ],
      ),
    );
  }
}

//////////////////// HOME PAGE ////////////////////

class AlumniHomePage extends StatelessWidget {
  const AlumniHomePage({super.key});

  String greet() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good Morning";
    if (h < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${greet()}, Alumni 👋",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.work_outline, size: 120, color: Colors.blue),
        ],
      ),
    );
  }
}