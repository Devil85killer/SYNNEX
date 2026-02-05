import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // kIsWeb ke liye

// ⚠️ IMPORTANT: Apne path ke hisab se adjust karein
import '../chat/channel_page.dart'; 
// import 'search_users_page.dart'; // ⚠️ Agar Search page banaya hai toh uncomment karein

class AlumniChatListPage extends StatefulWidget {
  const AlumniChatListPage({super.key});

  @override
  State<AlumniChatListPage> createState() => _AlumniChatListPageState();
}

class _AlumniChatListPageState extends State<AlumniChatListPage> with SingleTickerProviderStateMixin {
  final String myUid = FirebaseAuth.instance.currentUser!.uid;
  late TabController _tabController;

  // User Data
  String? myChatId;
  String? myJwt;
  String? myName;
  bool _isLoadingDetails = true; // Main Loader

  // Data Lists
  List<dynamic> _chatList = [];
  List<dynamic> _callList = [];
  bool _isLoadingChats = true;
  bool _isLoadingCalls = true;

  // ⚠️ Ensure correct URL
  String get baseUrl => kIsWeb ? "https://synnex.onrender.com" : "https://synnex.onrender.com";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); 
    _fetchMyDetails();
  }

  // 1. FETCH USER DETAILS
  Future<void> _fetchMyDetails() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('alumni_users').doc(myUid).get();
      if (!doc.exists) doc = await FirebaseFirestore.instance.collection('teachers').doc(myUid).get();
      if (!doc.exists) doc = await FirebaseFirestore.instance.collection('students').doc(myUid).get();

      if (doc.exists && mounted) {
        setState(() {
          myJwt = doc.data()?['chatifyJwt']?.toString();
          myChatId = doc.data()?['chatifyUserId']?.toString();
          myName = doc.data()?['name']?.toString();
          _isLoadingDetails = false;
        });
        
        if (myChatId != null) {
          _fetchChatsFromAPI();
          _fetchCallLogs();
        }
      } else {
        if (mounted) setState(() => _isLoadingDetails = false);
      }
    } catch (e) {
      print("Error details: $e");
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  // 2. FETCH CHATS
  Future<void> _fetchChatsFromAPI() async {
    if (myJwt == null) return;
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/chats"),
        headers: {"Authorization": "Bearer $myJwt", "Content-Type": "application/json"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _chatList = data['data'] ?? [];
            _isLoadingChats = false;
          });
        }
      }
    } catch (e) {
      print("Error chats: $e");
    } finally {
      if (mounted) setState(() => _isLoadingChats = false);
    }
  }

  // 3. FETCH CALLS
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
            _callList = data['data'] ?? [];
            _isLoadingCalls = false;
          });
        }
      }
    } catch (e) {
      print("Error calls: $e");
    } finally {
      if (mounted) setState(() => _isLoadingCalls = false);
    }
  }

  // Helpers
  String _formatTime(String? dateStr) {
    if (dateStr == null) return "";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('hh:mm a').format(date);
    } catch (e) { return ""; }
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
        title: const Text("Alumni Chats"),
        backgroundColor: Colors.indigo.shade800,
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

      // ✅ MAIN BODY
      body: _isLoadingDetails 
        ? const Center(child: CircularProgressIndicator()) 
        : TabBarView(
            controller: _tabController,
            children: [
              _buildChatListTab(),   
              _buildCallHistoryTab(), 
            ],
          ),

      // 🔥 HERE IS THE BUTTON YOU ASKED FOR
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo.shade800,
        child: const Icon(Icons.message, color: Colors.white),
        onPressed: () {
          // TODO: Yahan 'Search Users' page par navigate karo
          // Navigator.push(context, MaterialPageRoute(builder: (_) => SearchUsersPage()));
          print("Navigate to Search Users / New Chat Page");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("New Chat / Search feature coming soon!"))
          );
        },
      ),
    );
  }

  // ---------------------------------------------------
  // 💬 TAB 1: CHAT LIST
  // ---------------------------------------------------
  Widget _buildChatListTab() {
    if (_isLoadingChats) return const Center(child: CircularProgressIndicator());
    if (_chatList.isEmpty) return const Center(child: Text("No conversations yet"));

    return RefreshIndicator(
      onRefresh: _fetchChatsFromAPI,
      child: ListView.separated(
        itemCount: _chatList.length,
        separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 70),
        itemBuilder: (context, index) {
          final chat = _chatList[index];
          final otherName = chat['name']?.toString() ?? "User";
          final lastMsg = chat['lastMessage']?.toString() ?? "";
          final otherChatId = chat['chatId']?.toString();
          final timeStr = chat['lastMessageAt']?.toString();
          final unreadCount = chat['unreadCount'] ?? 0;
          final isUnread = unreadCount > 0;

          return ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.indigo.shade100,
              child: Text(otherName.isNotEmpty ? otherName[0].toUpperCase() : "?", 
                style: TextStyle(color: Colors.indigo.shade900, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, 
              style: TextStyle(color: isUnread ? Colors.black87 : Colors.grey, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_formatTime(timeStr), style: TextStyle(fontSize: 11, color: isUnread ? Colors.indigo : Colors.grey)),
                if (isUnread) ...[const SizedBox(height: 5), const CircleAvatar(radius: 5, backgroundColor: Colors.indigo)]
              ],
            ),
            onTap: () async {
              if (myChatId != null && myJwt != null && otherChatId != null) {
                final List<String> ids = [myChatId!, otherChatId];
                ids.sort();
                final roomId = ids.join("___");

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChannelPage(
                      roomId: roomId, me: myChatId!, other: otherChatId, otherName: otherName, jwt: myJwt!,
                      myUid: myUid, myName: myName ?? "Alumni", otherUid: "api_user",
                    ),
                  ),
                );
                _fetchChatsFromAPI();
              }
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------
  // 📞 TAB 2: CALL HISTORY
  // ---------------------------------------------------
  Widget _buildCallHistoryTab() {
    if (_isLoadingCalls) return const Center(child: CircularProgressIndicator());
    if (_callList.isEmpty) return const Center(child: Text("No recent calls"));

    return RefreshIndicator(
      onRefresh: _fetchCallLogs,
      child: ListView.builder(
        itemCount: _callList.length,
        itemBuilder: (context, index) {
          final call = _callList[index];
          final isOutgoing = call['callerId'] == myChatId;
          final name = isOutgoing ? call['receiverName'] : call['callerName'];
          final status = call['status'];
          final type = call['type'];

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
            trailing: Icon(type == 'video' ? Icons.videocam : Icons.call, color: Colors.indigo.shade800),
          );
        },
      ),
    );
  }
}