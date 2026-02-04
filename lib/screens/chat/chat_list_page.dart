import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // kIsWeb ke liye
import 'channel_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with SingleTickerProviderStateMixin {
  final String myUid = FirebaseAuth.instance.currentUser!.uid;
  late TabController _tabController;

  // User Data
  String? myChatId;
  String? myJwt;
  String? myName;
  bool loading = true;

  // Call History Data
  List<dynamic> _calls = [];
  bool _isLoadingCalls = true;

  // ⚠️ Ensure correct URL (Apne system ke hisab se)
  String get baseUrl => kIsWeb ? "http://localhost:3000" : "http://10.67.251.188:3000";

  @override
  void initState() {
    super.initState();
    // ✅ 2 Tabs: Chats aur Calls
    _tabController = TabController(length: 2, vsync: this); 
    _fetchMyDetails();
  }

  // 1. FETCH DETAILS (Student/Teacher/Alumni)
  Future<void> _fetchMyDetails() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('students').doc(myUid).get();
      if (!doc.exists) doc = await FirebaseFirestore.instance.collection('teachers').doc(myUid).get();
      if (!doc.exists) doc = await FirebaseFirestore.instance.collection('alumni_users').doc(myUid).get();

      if (doc.exists && mounted) {
        setState(() {
          myJwt = doc.data()?['chatifyJwt']?.toString();
          myChatId = doc.data()?['chatifyUserId']?.toString();
          myName = doc.data()?['name']?.toString();
          loading = false;
        });
        
        // Details milne ke baad Call History mangwao
        if (myChatId != null) {
          _fetchCallLogs();
        }
      } else {
        if(mounted) setState(() => loading = false);
      }
    } catch (e) {
      print("Error details: $e");
      if(mounted) setState(() => loading = false);
    }
  }

  // 2. FETCH CALL HISTORY API
  Future<void> _fetchCallLogs() async {
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
            _isLoadingCalls = false;
          });
        }
      }
    } catch (e) {
      print("Error calls: $e");
      if(mounted) setState(() => _isLoadingCalls = false);
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
      // 🔥 APP BAR WITH TABS (Ye zaroori hai WhatsApp look ke liye)
      appBar: AppBar(
        title: const Text("Chatify"),
        backgroundColor: const Color(0xFF075E54), // WhatsApp Theme Color
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
      backgroundColor: Colors.white,

      // 🔥 BODY WITH SWIPE VIEW
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatListTab(),   // Tab 1: Chats
          _buildCallHistoryTab(), // Tab 2: Calls
        ],
      ),
      
      // Dynamic FAB
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF25D366),
        child: Icon(_tabController.index == 0 ? Icons.message : Icons.add_call, color: Colors.white),
        onPressed: () {},
      ),
    );
  }

  // ---------------------------------------------------
  // 💬 TAB 1: CHAT LIST (Firestore Stream - Jo aapka pehle tha)
  // ---------------------------------------------------
  Widget _buildChatListTab() {
    if (loading) return const Center(child: CircularProgressIndicator());

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
                Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                const Text("No active chats", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final chats = snapshot.data!.docs;

        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 70),
          itemBuilder: (context, index) {
            final chat = chats[index].data() as Map<String, dynamic>;
            final otherUid = chats[index].id;
            final otherName = chat['name']?.toString() ?? "User";
            final lastMsg = chat['lastMessage']?.toString() ?? "";
            final otherChatId = chat['chatifyId']?.toString();
            final timestamp = chat['time'] as Timestamp?;
            final isUnread = chat['unread'] == true;

            return ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade100,
                child: Text(otherName.isNotEmpty ? otherName[0].toUpperCase() : "?", 
                  style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, 
                style: TextStyle(color: isUnread ? Colors.black87 : Colors.grey, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_formatChatTime(timestamp), style: TextStyle(fontSize: 11, color: isUnread ? const Color(0xFF25D366) : Colors.grey)),
                  if (isUnread) ...[const SizedBox(height: 5), const CircleAvatar(radius: 5, backgroundColor: Color(0xFF25D366))]
                ],
              ),
              onTap: () {
                if (myChatId != null && myJwt != null && otherChatId != null) {
                  final List<String> ids = [myChatId!, otherChatId];
                  ids.sort();
                  final roomId = ids.join("__");

                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChannelPage(
                    roomId: roomId, me: myChatId!, other: otherChatId, otherName: otherName, jwt: myJwt!,
                    myUid: myUid, myName: myName ?? "User", otherUid: otherUid,
                  )));
                }
              },
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------
  // 📞 TAB 2: CALL HISTORY (API Logic)
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
            trailing: Icon(type == 'video' ? Icons.videocam : Icons.call, color: const Color(0xFF075E54)),
          );
        },
      ),
    );
  }
}