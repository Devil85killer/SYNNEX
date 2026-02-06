import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screens/chat/channel_page.dart'; 

class AlumniChatListPage extends StatefulWidget {
  const AlumniChatListPage({super.key});

  @override
  State<AlumniChatListPage> createState() => _AlumniChatListPageState();
}

class _AlumniChatListPageState extends State<AlumniChatListPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _chatUsers = [];
  List<dynamic> _callLogs = [];
  String? myJwt;
  String? myUid;
  String? myName;

  late TabController _tabController;

  // 🔥 POWERFUL CACHE: Background sync ke liye
  final Map<String, String> _nameCache = {};
  StreamSubscription? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 1) {
        _fetchCallLogs();
      }
    });

    _loadUserAndData();
    _listenToActiveChats();
  }

  // 🔥 Background Listener: Firestore se names sync karne ke liye
  void _listenToActiveChats() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid == null) return;

    _chatSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('active_chats')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final String? cid = data['chatifyId']?.toString();
          final String? name = data['name']?.toString();
          if (cid != null && name != null) _nameCache[cid] = name;
        }
        setState(() {}); // UI Update
      }
    });
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
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
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchChatList() async {
    try {
      final res = await http.get(
        Uri.parse("https://synnex.onrender.com/api/auth/users"), 
        headers: {"Authorization": "Bearer $myJwt"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          final users = data['users'] ?? [];
          // Pre-populate cache from API
          for(var u in users) {
            if(u['_id'] != null && u['name'] != null) {
              _nameCache[u['_id']] = u['name'];
            }
          }
          setState(() => _chatUsers = users);
        }
      }
    } catch (e) {
      debugPrint("Error fetching chats: $e");
    }
  }

  Future<void> _fetchCallLogs() async {
    try {
      final res = await http.get(
        Uri.parse("https://synnex.onrender.com/api/calls/$myUid"), // ✅ Endpoint check kar lena
        headers: {"Authorization": "Bearer $myJwt"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() => _callLogs = data['data'] ?? []);
      }
    } catch (e) {
      debugPrint("Error fetching calls: $e");
    }
  }

  // 🔥 SAFE NAME RESOLVER
  String _getDisplayName(Map<String, dynamic> call) {
    final isOutgoing = call['callerId']?.toString() == myUid;
    final targetId = isOutgoing ? call['receiverId']?.toString() : call['callerId']?.toString();

    if (targetId == null) return "Unknown User";
    if (_nameCache.containsKey(targetId)) return _nameCache[targetId]!;

    // Fallback to API populated names
    return isOutgoing ? (call['receiverName'] ?? "User") : (call['callerName'] ?? "User");
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return "";
    try {
      return DateFormat('MMM d, h:mm a').format(DateTime.parse(dateStr).toLocal());
    } catch (e) { return ""; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alumni Connect"),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: "CHATS"), Tab(text: "CALLS")],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildChatList(), _buildCallList()],
            ),
    );
  }

  Widget _buildChatList() {
    if (_chatUsers.isEmpty) return const Center(child: Text("No users found."));
    
    return ListView.builder(
      itemCount: _chatUsers.length,
      itemBuilder: (context, index) {
        final user = _chatUsers[index];
        final name = user['name'] ?? user['displayName'] ?? "User";
        final role = user['role'] ?? "Student"; 
        final otherUid = user['_id'] ?? "";

        if (otherUid == myUid) return const SizedBox.shrink();

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.indigo.shade100,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : "U", 
                 style: TextStyle(color: Colors.indigo.shade900, fontWeight: FontWeight.bold)),
          ),
          title: Text("$name ($role)", style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(user['email'] ?? ""),
          trailing: const Icon(Icons.chat_bubble_outline, color: Colors.indigo),
          onTap: () => _openChat(otherUid, name),
        );
      },
    );
  }

  Widget _buildCallList() {
    if (_callLogs.isEmpty) return const Center(child: Text("No recent calls."));

    return RefreshIndicator(
      onRefresh: _fetchCallLogs,
      child: ListView.builder(
        itemCount: _callLogs.length,
        itemBuilder: (context, index) {
          final call = _callLogs[index];
          final isVideo = call['type'] == 'video';
          final status = call['status']?.toString().toLowerCase();
          final isOutgoing = call['callerId']?.toString() == myUid;

          IconData statusIcon = status == 'missed' ? Icons.call_missed : (isOutgoing ? Icons.call_made : Icons.call_received);
          Color statusColor = status == 'missed' ? Colors.red : (isOutgoing ? Colors.grey : Colors.green);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: Icon(isVideo ? Icons.videocam : Icons.call, color: Colors.indigo),
            ),
            title: Text(_getDisplayName(call), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 5),
                Text(_formatTime(call['timestamp'] ?? call['createdAt'])),
              ],
            ),
            trailing: Icon(isVideo ? Icons.videocam : Icons.call, color: Colors.indigo.shade300),
          );
        },
      ),
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
    ).then((_) => _fetchCallLogs());
  }
}