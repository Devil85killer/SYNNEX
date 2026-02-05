import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/chat/channel_page.dart'; // Apna ChannelPage ka path check kar lena

class AlumniChatListPage extends StatefulWidget {
  const AlumniChatListPage({super.key});

  @override
  State<AlumniChatListPage> createState() => _AlumniChatListPageState();
}

class _AlumniChatListPageState extends State<AlumniChatListPage> {
  bool _isLoading = true;
  List<dynamic> _chatUsers = [];
  List<dynamic> _callLogs = [];
  String? myJwt;
  String? myUid;
  String? myName;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myJwt = prefs.getString('token');
      // ⚠️ Make sure ye MongoDB wali ID ho
      myUid = prefs.getString('uid'); 
      myName = prefs.getString('name');
    });

    if (myJwt != null) {
      await _fetchChatList();
      await _fetchCallLogs();
    } else {
      setState(() => _isLoading = false);
    }
  }

  // 1. Fetch Users (Chats Tab ke liye)
  Future<void> _fetchChatList() async {
    try {
      final res = await http.get(
        Uri.parse("https://synnex.onrender.com/api/auth/users"), 
        headers: {"Authorization": "Bearer $myJwt"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() => _chatUsers = data['users'] ?? []);
      }
    } catch (e) {
      debugPrint("Error fetching chats: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Fetch Call Logs (CLS Tab ke liye)
  Future<void> _fetchCallLogs() async {
    try {
      final res = await http.get(
        Uri.parse("https://synnex.onrender.com/api/calls/history"),
        headers: {"Authorization": "Bearer $myJwt"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() => _callLogs = data['calls'] ?? []);
      }
    } catch (e) {
      debugPrint("Error fetching calls: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Do Tabs: Chats aur Calls
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Alumni Connect"),
          backgroundColor: Colors.indigo.shade800,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: "CHATS"),
              Tab(text: "CLS"), // Call Logs Tab
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildChatList(), // Tab 1 Content
                  _buildCallList(), // Tab 2 Content
                ],
              ),
      ),
    );
  }

  // 🔹 Tab 1: Chat List (Name + Role Fix)
  Widget _buildChatList() {
    if (_chatUsers.isEmpty) return const Center(child: Text("No users found."));
    
    return ListView.builder(
      itemCount: _chatUsers.length,
      itemBuilder: (context, index) {
        final user = _chatUsers[index];
        
        // Data Extraction
        final name = user['name'] ?? user['displayName'] ?? "Unknown";
        final role = user['role'] ?? "Student"; // Default Role
        final email = user['email'] ?? "";
        final otherUid = user['_id'] ?? ""; // MongoDB ID

        if (otherUid == myUid) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade100,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?"),
            ),
            // 🔥 NAME + ROLE DISPLAY FIX
            title: Text(
              "$name ($role)", 
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(email),
            trailing: const Icon(Icons.chat_bubble_outline, color: Colors.indigo),
            onTap: () => _openChat(otherUid, name),
          ),
        );
      },
    );
  }

  // 🔹 Tab 2: Call Logs (CLS)
  Widget _buildCallList() {
    if (_callLogs.isEmpty) return const Center(child: Text("No recent calls."));

    return ListView.builder(
      itemCount: _callLogs.length,
      itemBuilder: (context, index) {
        final call = _callLogs[index];
        final isVideo = call['type'] == 'video';
        final callerName = call['callerName'] ?? "Unknown";
        final status = call['status'] ?? "Missed";
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: status == 'missed' ? Colors.red.shade50 : Colors.green.shade50,
            child: Icon(
              isVideo ? Icons.videocam : Icons.call, 
              color: status == 'missed' ? Colors.red : Colors.green
            ),
          ),
          title: Text(callerName),
          subtitle: Text(status.toUpperCase()),
          trailing: const Icon(Icons.info_outline, size: 20, color: Colors.grey),
        );
      },
    );
  }

  // 🔥 IMPORTANT: Room ID Generation Fix (___)
  void _openChat(String otherUid, String otherName) {
    if (myUid == null) return;

    List<String> ids = [myUid!, otherUid];
    ids.sort(); // Sort karna zaroori hai
    
    // ✅ Fix: Use 3 underscores '___' to match ChannelPage logic
    String roomId = ids.join("___"); 

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChannelPage(
          roomId: roomId,
          me: myUid!,
          other: otherUid,
          otherName: otherName,
          jwt: myJwt!,
          myUid: myUid!,
          myName: myName ?? "Me",
          otherUid: otherUid,
        ),
      ),
    );
  }
}