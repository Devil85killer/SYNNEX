import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; 
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
  String? myMongoId; // MongoDB _id (Chatify ID)
  String? myJwt;
  String? myName;
  bool _loading = true;

  // Data Lists
  List<dynamic> _chats = [];
  List<dynamic> _calls = [];
  bool _isLoadingChats = true;
  bool _isLoadingCalls = true;

  // ⚠️ URL Check
  String get baseUrl => "https://synnex.onrender.com";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); 
    _fetchMyDetails();
  }

  // 1. FETCH USER DETAILS & SYNC
  Future<void> _fetchMyDetails() async {
    try {
      // Check Collections
      var doc = await FirebaseFirestore.instance.collection('students').doc(myUid).get();
      if (!doc.exists) doc = await FirebaseFirestore.instance.collection('teachers').doc(myUid).get();
      if (!doc.exists) doc = await FirebaseFirestore.instance.collection('alumni_users').doc(myUid).get();

      if (doc.exists && mounted) {
        setState(() {
          myJwt = doc.data()?['chatifyJwt']?.toString();
          myMongoId = doc.data()?['chatifyUserId']?.toString(); // MongoDB ID zaroori hai
          myName = doc.data()?['name']?.toString();
          _loading = false;
        });
        
        // IDs milne ke baad hi APIs call karo
        if (myMongoId != null) {
          _fetchChats();
          _fetchCallLogs();
        }
      } else {
        if(mounted) setState(() => _loading = false);
      }
    } catch (e) {
      print("Error details: $e");
      if(mounted) setState(() => _loading = false);
    }
  }

  // 2. FETCH CHATS (MongoDB API)
  Future<void> _fetchChats() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/chats/$myMongoId"), // ✅ User specific chats
        headers: {"Authorization": "Bearer $myJwt"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _chats = data['chats'] ?? [];
            _isLoadingChats = false;
          });
        }
      }
    } catch (e) {
      print("Error chats: $e");
      if(mounted) setState(() => _isLoadingChats = false);
    }
  }

  // 3. FETCH CALLS (MongoDB API)
  Future<void> _fetchCallLogs() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/calls/$myMongoId"),
        headers: {"Authorization": "Bearer $myJwt"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _calls = data['calls'] ?? [];
            _isLoadingCalls = false;
          });
        }
      }
    } catch (e) {
      print("Error calls: $e");
      if(mounted) setState(() => _isLoadingCalls = false);
    }
  }

  // Formatter
  String _formatTime(String? dateStr) {
    if (dateStr == null) return "";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (date.day == now.day) return DateFormat('hh:mm a').format(date);
      return DateFormat('MMM d').format(date);
    } catch (e) { return ""; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chatify"),
        backgroundColor: const Color(0xFF075E54),
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

      body: _loading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChatListTab(), 
                _buildCallHistoryTab(),
              ],
            ),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF25D366),
        child: Icon(_tabController.index == 0 ? Icons.message : Icons.add_call, color: Colors.white),
        onPressed: () {
           // New Chat Logic Here
        },
      ),
    );
  }

  // ---------------------------------------------------
  // 💬 TAB 1: CHAT LIST (Updated for MongoDB)
  // ---------------------------------------------------
  Widget _buildChatListTab() {
    if (_isLoadingChats) return const Center(child: CircularProgressIndicator());
    if (_chats.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: _fetchChats,
      child: ListView.separated(
        itemCount: _chats.length,
        separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 70),
        itemBuilder: (context, index) {
          final chat = _chats[index];
          
          // 🔥 Logic: Find Other User from Populated Members
          final members = chat['members'] as List;
          var otherUser = members.firstWhere(
            (m) => m['_id'] != myMongoId, 
            orElse: () => null
          );

          // Safety: Agar khud se chat hai ya data missing hai
          if (otherUser == null) return const SizedBox();

          final otherName = otherUser['displayName'] ?? otherUser['email'] ?? "User";
          final photo = otherUser['photoURL'];
          final lastMsg = chat['lastMessage'] ?? "";
          final timeStr = chat['updatedAt']; // Backend 'updatedAt' bhejta hai

          return ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: (photo != null && photo != "") ? NetworkImage(photo) : null,
              child: (photo == null || photo == "") 
                  ? Text(otherName[0].toUpperCase(), style: TextStyle(color: Colors.blue.shade900)) 
                  : null,
            ),
            title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(_formatTime(timeStr), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            onTap: () {
               // Open Chat
               Navigator.push(context, MaterialPageRoute(builder: (_) => ChannelPage(
                  roomId: chat['roomId'] ?? chat['_id'], 
                  me: myMongoId!, 
                  other: otherUser['_id'], // MongoDB ID bhejo
                  otherName: otherName, 
                  jwt: myJwt!,
                  myUid: myUid, 
                  myName: myName ?? "User",
               ))).then((_) => _fetchChats()); // Wapas aane par refresh
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------
  // 📞 TAB 2: CALL HISTORY (Updated Keys)
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
          
          // 🔥 Caller/Receiver Logic with Objects
          // Note: Backend populated objects bhej raha hai (callerId: { _id: "..." })
          final callerObj = call['callerId'];
          final receiverObj = call['receiverId'];
          
          // Check karo main Caller hu ya Receiver
          final isOutgoing = callerObj['_id'] == myMongoId;
          
          final otherUser = isOutgoing ? receiverObj : callerObj;
          final name = otherUser?['displayName'] ?? "Unknown";
          final photo = otherUser?['photoURL'];
          
          final status = call['status'];
          final type = call['type'];

          IconData arrowIcon = status == 'missed' ? Icons.call_missed : (isOutgoing ? Icons.call_made : Icons.call_received);
          Color arrowColor = status == 'missed' ? Colors.red : Colors.green;

          return ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (photo != null && photo != "") ? NetworkImage(photo) : null,
              child: (photo == null || photo == "") ? const Icon(Icons.person, color: Colors.grey) : null,
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                Icon(arrowIcon, size: 16, color: arrowColor),
                const SizedBox(width: 5),
                Text(_formatTime(call['startedAt'])), // ✅ 'startedAt' use karo
              ],
            ),
            trailing: Icon(type == 'video' ? Icons.videocam : Icons.call, color: const Color(0xFF075E54)),
          );
        },
      ),
    );
  }
}