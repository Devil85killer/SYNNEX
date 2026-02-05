import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // kIsWeb ke liye
import 'channel_page.dart'; // Aapka Chat Screen

class MainChatScreen extends StatefulWidget {
  const MainChatScreen({super.key});

  @override
  State<MainChatScreen> createState() => _MainChatScreenState();
}

class _MainChatScreenState extends State<MainChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String myUid = FirebaseAuth.instance.currentUser!.uid;
  
  // User Data
  String? myChatId;
  String? myJwt;
  String? myName;
  bool _isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 Tabs: CHATS, CALLS
    _fetchMyDetails();
  }

  // 1. User Details Fetch (Student/Teacher/Alumni sabke liye)
  Future<void> _fetchMyDetails() async {
    try {
      // Check Alumni
      var doc = await FirebaseFirestore.instance.collection('alumni_users').doc(myUid).get();
      
      if (!doc.exists) {
        // Check Teachers
        doc = await FirebaseFirestore.instance.collection('teachers').doc(myUid).get();
      }
      if (!doc.exists) {
        // Check Students
        doc = await FirebaseFirestore.instance.collection('users').doc(myUid).get(); // Students collection name check karlena
      }

      if (doc.exists && mounted) {
        setState(() {
          myJwt = doc.data()?['chatifyJwt']?.toString();
          myChatId = doc.data()?['chatifyUserId']?.toString();
          myName = doc.data()?['name']?.toString() ?? "User";
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      print("Error fetching user details: $e");
      if(mounted) setState(() => _isLoadingDetails = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔥 WHATSAPP STYLE APP BAR
      appBar: AppBar(
        title: const Text("Chatify"),
        backgroundColor: const Color(0xFF075E54), // WhatsApp Teal Color
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
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      
      // 🔥 SLIDEABLE BODY
      body: _isLoadingDetails
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Chat List
                ChatListTab(myChatId: myChatId!, myJwt: myJwt!, myName: myName!, myUid: myUid),
                
                // TAB 2: Call History
                CallHistoryTab(myChatId: myChatId!, myJwt: myJwt!, myUid: myUid),
              ],
            ),
            
      // 🔥 DYNAMIC FAB (Icon badlega)
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF25D366), // WhatsApp Light Green
        child: Icon(_tabController.index == 0 ? Icons.message : Icons.add_call, color: Colors.white),
        onPressed: () {
           // Handle New Chat or Call
        },
      ),
    );
  }
}

// ==========================================
// 💬 TAB 1: CHAT LIST (API Based)
// ==========================================
class ChatListTab extends StatefulWidget {
  final String myChatId, myJwt, myName, myUid;
  const ChatListTab({super.key, required this.myChatId, required this.myJwt, required this.myName, required this.myUid});

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
    _fetchChatsFromAPI();
  }

  Future<void> _fetchChatsFromAPI() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/chats"),
        headers: {"Authorization": "Bearer ${widget.myJwt}", "Content-Type": "application/json"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _chatList = data['data'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) { if(mounted) setState(() => _isLoading = false); }
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
          
          return ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, color: Colors.white, size: 30),
            ),
            title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(_formatTime(timeStr), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            onTap: () async {
              if (otherChatId != null) {
                final List<String> ids = [widget.myChatId.toLowerCase(), otherChatId.trim().toLowerCase()];
                ids.sort();
                final roomId = ids.join("___");

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChannelPage(
                      roomId: roomId,
                      me: widget.myChatId,
                      other: otherChatId,
                      otherName: otherName,
                      jwt: widget.myJwt,
                      myUid: widget.myUid,
                      myName: widget.myName,
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
}

// ==========================================
// 📞 TAB 2: CALL HISTORY (API Based)
// ==========================================
class CallHistoryTab extends StatefulWidget {
  final String myChatId, myJwt, myUid;
  const CallHistoryTab({super.key, required this.myChatId, required this.myJwt, required this.myUid});

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
        Uri.parse("$baseUrl/api/calls/${widget.myChatId}"), 
        headers: {"Authorization": "Bearer ${widget.myJwt}"}
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _calls = data['data'];
            _isLoading = false;
          });
        }
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
          final isOutgoing = call['callerId'] == widget.myChatId;
          final name = isOutgoing ? call['receiverName'] : call['callerName'];
          final status = call['status'];
          
          return ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, color: Colors.white, size: 30),
            ),
            title: Text(name ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(children: [
              Icon(
                isOutgoing ? Icons.call_made : Icons.call_received, 
                size: 16, 
                color: status == 'missed' ? Colors.red : Colors.green
              ),
              const SizedBox(width: 5),
              Text(_formatDateTime(call['timestamp']))
            ]),
            trailing: Icon(call['type'] == 'video' ? Icons.videocam : Icons.call, color: const Color(0xFF075E54)),
          );
        }
      ),
    );
  }
}