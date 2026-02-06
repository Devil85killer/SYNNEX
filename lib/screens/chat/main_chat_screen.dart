import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'channel_page.dart'; // Tera Chat Screen

class MainChatScreen extends StatefulWidget {
  const MainChatScreen({super.key});

  @override
  State<MainChatScreen> createState() => _MainChatScreenState();
}

class _MainChatScreenState extends State<MainChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String myUid = FirebaseAuth.instance.currentUser!.uid;
  
  // User Data
  String? myMongoId; // Backend ki MongoDB ID (chatId)
  String? myJwt;
  String? myName;
  bool _isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMyDetails();
  }

  // 1. Fetch My Details (Firebase -> MongoDB ID sync)
  Future<void> _fetchMyDetails() async {
    try {
      // Pehle 'users' check karo (sabse common)
      var doc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      
      if (!doc.exists) {
        doc = await FirebaseFirestore.instance.collection('alumni_users').doc(myUid).get();
      }
      if (!doc.exists) {
        doc = await FirebaseFirestore.instance.collection('teachers').doc(myUid).get();
      }

      if (doc.exists && mounted) {
        setState(() {
          // Backend se jo 'sync-user' response mein ID mili thi, wo yahan honi chahiye
          // Agar Firestore mein save nahi hai, toh API call karke lana padega
          myJwt = doc.data()?['chatifyJwt']?.toString();
          myMongoId = doc.data()?['chatifyUserId']?.toString(); // Ye MongoDB _id honi chahiye
          myName = doc.data()?['name']?.toString() ?? "User";
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      print("Error fetching details: $e");
      if(mounted) setState(() => _isLoadingDetails = false);
    }
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
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.more_vert), 
            onPressed: () {
               // Logout or Settings logic
            }
          ),
        ],
      ),
      
      body: _isLoadingDetails
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Chat List
                ChatListTab(myId: myMongoId!, myJwt: myJwt!, myName: myName!, myUid: myUid),
                
                // TAB 2: Call History
                CallHistoryTab(myId: myMongoId!, myJwt: myJwt!),
              ],
            ),
            
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF25D366),
        child: Icon(_tabController.index == 0 ? Icons.message : Icons.add_call, color: Colors.white),
        onPressed: () {
            // New Chat Logic (Search Screen khol sakte ho)
        },
      ),
    );
  }
}

// ==========================================
// 💬 TAB 1: CHAT LIST (Corrected Parsing)
// ==========================================
class ChatListTab extends StatefulWidget {
  final String myId, myJwt, myName, myUid;
  const ChatListTab({super.key, required this.myId, required this.myJwt, required this.myName, required this.myUid});

  @override
  State<ChatListTab> createState() => _ChatListTabState();
}

class _ChatListTabState extends State<ChatListTab> {
  List<dynamic> _chatList = [];
  bool _isLoading = true;
  String get baseUrl => kIsWeb ? "https://synnex.onrender.com" : "https://synnex.onrender.com";

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/chats/${widget.myId}"), // ✅ Backend route update check karlena
        headers: {"Authorization": "Bearer ${widget.myJwt}"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _chatList = data['chats'] ?? []; // ✅ Backend key 'chats' hai
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return "";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('hh:mm a').format(date);
    } catch (e) { return ""; }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_chatList.isEmpty) return const Center(child: Text("Start a new conversation!"));

    return RefreshIndicator(
      onRefresh: _fetchChats,
      child: ListView.separated(
        itemCount: _chatList.length,
        separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 70), 
        itemBuilder: (context, index) {
          final chat = _chatList[index];
          
          // 🔥 LOGIC: Identify Other User from 'members' array
          final members = chat['members'] as List;
          final otherUser = members.firstWhere(
            (m) => m['_id'] != widget.myId, 
            orElse: () => null
          );

          if (otherUser == null) return const SizedBox(); // Safety check

          final otherName = otherUser['displayName'] ?? otherUser['email'] ?? "Unknown";
          final otherPhoto = otherUser['photoURL']; // Backend se aa raha hai
          final lastMsg = chat['lastMessage'] ?? "";
          final timeStr = chat['updatedAt']; // Backend 'updatedAt' bhejta hai default

          return ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: (otherPhoto != null && otherPhoto != "") 
                  ? NetworkImage(otherPhoto) 
                  : null,
              child: (otherPhoto == null || otherPhoto == "") 
                  ? const Icon(Icons.person, color: Colors.white) 
                  : null,
            ),
            title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(_formatTime(timeStr), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            onTap: () async {
              // Open Chat Screen
              // ✅ Room ID Backend se direct aa rahi hai
              final roomId = chat['roomId'] ?? chat['_id']; 
              
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChannelPage(
                    roomId: roomId,
                    me: widget.myId,
                    other: otherUser['_id'],
                    otherName: otherName,
                    jwt: widget.myJwt,
                    myUid: widget.myUid,
                    myName: widget.myName,
                  ),
                ),
              );
              _fetchChats(); // Wapas aane par refresh
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 📞 TAB 2: CALL HISTORY (Corrected Logic)
// ==========================================
class CallHistoryTab extends StatefulWidget {
  final String myId, myJwt;
  const CallHistoryTab({super.key, required this.myId, required this.myJwt});

  @override
  State<CallHistoryTab> createState() => _CallHistoryTabState();
}

class _CallHistoryTabState extends State<CallHistoryTab> {
  List<dynamic> _calls = [];
  bool _isLoading = true;
  String get baseUrl => kIsWeb ? "https://synnex.onrender.com" : "https://synnex.onrender.com";

  @override
  void initState() {
    super.initState();
    _fetchCalls();
  }

  Future<void> _fetchCalls() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/calls/${widget.myId}"), 
        headers: {"Authorization": "Bearer ${widget.myJwt}"}
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _calls = data['calls'] ?? []; // ✅ Backend key 'calls' hai
            _isLoading = false;
          });
        }
      } else {
         if(mounted) setState(() => _isLoading = false);
      }
    } catch (e) { if(mounted) setState(() => _isLoading = false); }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return "";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (date.day == now.day) return "Today, ${DateFormat('h:mm a').format(date)}";
      return DateFormat('MMM d, h:mm a').format(date);
    } catch (e) { return ""; }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_calls.isEmpty) return const Center(child: Text("No recent calls"));

    return RefreshIndicator(
      onRefresh: _fetchCalls,
      child: ListView.builder(
        itemCount: _calls.length,
        itemBuilder: (ctx, i) {
          final call = _calls[i];
          
          // 🔥 Logic: Check karo main Caller hoon ya Receiver
          final isOutgoing = call['callerId']['_id'] == widget.myId;
          
          // Populated Data Use karo
          final otherUser = isOutgoing ? call['receiverId'] : call['callerId'];
          final name = otherUser['displayName'] ?? otherUser['email'] ?? "Unknown";
          final photo = otherUser['photoURL'];
          
          final status = call['status']; // 'missed', 'ended', 'rejected'
          final type = call['type']; // 'audio', 'video'
          
          // Icon Color Logic
          Color iconColor = Colors.green;
          if (status == 'missed' || status == 'rejected') iconColor = Colors.red;

          return ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: (photo != null && photo != "") ? NetworkImage(photo) : null,
              child: (photo == null || photo == "") ? const Icon(Icons.person, color: Colors.white) : null,
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(children: [
              Icon(
                isOutgoing ? Icons.call_made : Icons.call_received, 
                size: 16, 
                color: iconColor
              ),
              const SizedBox(width: 5),
              Text(_formatDateTime(call['startedAt'])) // ✅ Backend key 'startedAt'
            ]),
            trailing: Icon(
               type == 'video' ? Icons.videocam : Icons.call, 
               color: const Color(0xFF075E54)
            ),
          );
        },
      ),
    );
  }
}