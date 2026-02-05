import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // kIsWeb ke liye

// ✅ IMPORT FIX: Ensure path is correct
import 'package:SYNNEX/screens/chat/channel_page.dart'; 

class StudentChatListPage extends StatefulWidget {
  const StudentChatListPage({super.key});

  @override
  State<StudentChatListPage> createState() => _StudentChatListPageState();
}

class _StudentChatListPageState extends State<StudentChatListPage> with SingleTickerProviderStateMixin {
  final String myUid = FirebaseAuth.instance.currentUser!.uid;
  late TabController _tabController;

  // User Data
  String? myChatId;
  String? myJwt;
  String? myName;
  bool _isLoadingDetails = true; // Main Loader

  // Call History Data
  List<dynamic> _calls = [];
  bool _isLoadingCalls = true; // Call Loader

  // ⚠️ Ensure correct URL
  String get baseUrl => kIsWeb ? "https://synnex.onrender.com" : "https://synnex.onrender.com";

  @override
  void initState() {
    super.initState();
    // ✅ 2 Tabs: CHATS & CALLS
    _tabController = TabController(length: 2, vsync: this);
    
    // Tab change hone par calls refresh karo
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 1) {
        _fetchCallLogs();
      }
    });

    _fetchMyDetails();
  }

  // 1. FETCH STUDENT DETAILS
  Future<void> _fetchMyDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('students').doc(myUid).get();
      
      if (doc.exists && mounted) {
        setState(() {
          myJwt = doc.data()?['chatifyJwt']?.toString();
          myChatId = doc.data()?['chatifyUserId']?.toString();
          myName = doc.data()?['name']?.toString();
          _isLoadingDetails = false;
        });
        
        // Agar ID mili toh Calls fetch karo
        if (myChatId != null) {
          _fetchCallLogs();
        } else {
           if (mounted) setState(() => _isLoadingCalls = false);
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingDetails = false;
            _isLoadingCalls = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching details: $e");
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
          _isLoadingCalls = false;
        });
      }
    }
  }

  // 2. FETCH CALL HISTORY (API)
  Future<void> _fetchCallLogs() async {
    if (myChatId == null) return;
    
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/calls/$myChatId"),
        headers: {"Authorization": "Bearer $myJwt"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _calls = data['data'];
          });
        }
      }
    } catch (e) {
      print("Error calls: $e");
    } finally {
      // ✅ FIX: Loader band zaroor hoga
      if (mounted) setState(() => _isLoadingCalls = false);
    }
  }

  // Time Formatters
  String _formatChatTime(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    return DateFormat('hh:mm a').format(date);
  }

  String _formatCallTime(String? dateStr) {
    if (dateStr == null) return "";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM d, h:mm a').format(date);
    } catch (e) { return ""; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Chats"),
        backgroundColor: Colors.blue.shade800, 
        foregroundColor: Colors.white,
        elevation: 0.7,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: "CHATS"),
            Tab(text: "CALLS"),
          ],
        ),
      ),
      backgroundColor: Colors.grey.shade100,

      // 🔥 MAIN BODY
      body: _isLoadingDetails
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildChatListTab(),   // Tab 1
              _buildCallHistoryTab(), // Tab 2
            ],
          ),

      // 🔥 FLOATING ACTION BUTTON ADDED (Student Theme: Blue)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.message, color: Colors.white),
        onPressed: () {
          // TODO: Navigate to Search Users Page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("New Chat / Search feature coming soon!")),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------
  // 💬 TAB 1: CHAT LIST
  // ---------------------------------------------------
  Widget _buildChatListTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('active_chats')
          .orderBy('time', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                const Text("No active chats", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final chats = snapshot.data!.docs;

        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (ctx, i) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chat = chats[index].data() as Map<String, dynamic>;
            final otherUid = chats[index].id;
            final otherName = chat['name']?.toString() ?? "User";
            final lastMsg = chat['lastMessage']?.toString() ?? "";
            final otherChatId = chat['chatifyId']?.toString();
            final timestamp = chat['time'] as Timestamp?;
            final isUnread = chat['unread'] == true;

            return ListTile(
              tileColor: Colors.white,
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade100,
                child: Text(otherName.isNotEmpty ? otherName[0].toUpperCase() : "?", 
                  style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, 
                style: TextStyle(color: isUnread ? Colors.black : Colors.grey, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_formatChatTime(timestamp), style: TextStyle(fontSize: 11, color: isUnread ? Colors.blue : Colors.grey)),
                  if (isUnread) ...[const SizedBox(height: 5), const CircleAvatar(radius: 5, backgroundColor: Colors.blue)]
                ],
              ),
              onTap: () async {
                if (myChatId != null && myJwt != null && otherChatId != null) {
                  final List<String> ids = [myChatId!, otherChatId];
                  ids.sort();
                  final roomId = ids.join("___");

                  await Navigator.push(context, MaterialPageRoute(builder: (_) => ChannelPage(
                    roomId: roomId, me: myChatId!, other: otherChatId, otherName: otherName, jwt: myJwt!,
                    myUid: myUid, myName: myName ?? "Student", otherUid: otherUid,
                  )));
                  
                  _fetchCallLogs(); // Refresh on return
                }
              },
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------
  // 📞 TAB 2: CALL HISTORY
  // ---------------------------------------------------
  Widget _buildCallHistoryTab() {
    if (_isLoadingCalls) return const Center(child: CircularProgressIndicator());
    
    if (_calls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.call_end_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text("No recent calls", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCallLogs,
      child: ListView.builder(
        itemCount: _calls.length,
        itemBuilder: (context, index) {
          final call = _calls[index];
          final isOutgoing = call['callerId'] == myChatId;
          final name = isOutgoing ? call['receiverName'] : call['callerName'];
          final status = call['status'];
          final type = call['type'];

          // Icon Logic
          IconData arrowIcon = status == 'missed' ? Icons.call_missed : (isOutgoing ? Icons.call_made : Icons.call_received);
          Color arrowColor = status == 'missed' ? Colors.red : Colors.green;

          return ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.person, color: Colors.grey, size: 30),
            ),
            title: Text(name ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                Icon(arrowIcon, size: 16, color: arrowColor),
                const SizedBox(width: 5),
                Text(_formatCallTime(call['timestamp'])),
              ],
            ),
            trailing: Icon(type == 'video' ? Icons.videocam : Icons.call, color: Colors.blue.shade800),
          );
        },
      ),
    );
  }
}