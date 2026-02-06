import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/chat/channel_page.dart'; // Path check kar lena

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

  // 1. Fetch Users
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

  // 2. Fetch Call Logs
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
      length: 2, 
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
              Tab(text: "CLS"), 
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildChatList(), // Tab 1
                  _buildCallList(), // Tab 2
                ],
              ),
      ),
    );
  }

  // 🔹 Tab 1: Chat List (Sirf Name + Role)
  Widget _buildChatList() {
    if (_chatUsers.isEmpty) return const Center(child: Text("No users found."));
    
    return ListView.builder(
      itemCount: _chatUsers.length,
      itemBuilder: (context, index) {
        final user = _chatUsers[index];
        
        // ✅ DATA EXTRACTION (Clean)
        final name = user['name'] ?? user['displayName'] ?? "User"; // "Unknown" hata diya
        final role = user['role'] ?? "Student"; 
        final otherUid = user['_id'] ?? ""; 

        if (otherUid == myUid) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          elevation: 1, // Thoda clean look ke liye
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade100,
              radius: 24,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : "U",
                style: TextStyle(color: Colors.indigo.shade900, fontWeight: FontWeight.bold),
              ),
            ),
            
            // 🔥 SIRF NAME AUR ROLE (No Email, No Unknown)
            title: Text(
              "$name ($role)", 
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 16,
                color: Colors.black87
              ),
            ),
            
            // ✅ Subtitle hata diya taaki email na dikhe
            subtitle: null, 

            trailing: const Icon(Icons.chat_bubble_outline, color: Colors.indigo),
            onTap: () => _openChat(otherUid, name),
          ),
        );
      },
    );
  }

  // 🔹 Tab 2: Call Logs
  Widget _buildCallList() {
    if (_callLogs.isEmpty) return const Center(child: Text("No recent calls."));

    return ListView.builder(
      itemCount: _callLogs.length,
      itemBuilder: (context, index) {
        final call = _callLogs[index];
        final isVideo = call['type'] == 'video';
        final callerName = call['callerName'] ?? "User";
        final status = call['status'] ?? "Missed";
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: status == 'missed' ? Colors.red.shade50 : Colors.green.shade50,
            child: Icon(
              isVideo ? Icons.videocam : Icons.call, 
              color: status == 'missed' ? Colors.red : Colors.green
            ),
          ),
          title: Text(callerName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(status.toUpperCase(), style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.history, size: 20, color: Colors.grey),
        );
      },
    );
  }

  void _openChat(String otherUid, String otherName) {
    if (myUid == null) return;

    List<String> ids = [myUid!, otherUid];
    ids.sort(); 
    
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