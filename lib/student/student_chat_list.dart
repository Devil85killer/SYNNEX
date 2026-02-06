import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:synnex/screens/chat/channel_page.dart'; 

class StudentChatListPage extends StatefulWidget {
  const StudentChatListPage({super.key});

  @override
  State<StudentChatListPage> createState() => _StudentChatListPageState();
}

class _StudentChatListPageState extends State<StudentChatListPage> with SingleTickerProviderStateMixin {
  final String myUid = FirebaseAuth.instance.currentUser!.uid;
  late TabController _tabController;

  String? myChatId, myJwt, myName;
  bool _isLoadingDetails = true;
  List<dynamic> _calls = [];
  bool _isLoadingCalls = true;

  // 🔥 POWERFUL CACHE: Background listener se data yahan store hoga
  final Map<String, String> _nameCache = {};
  StreamSubscription? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Tab switch hone par calls refresh karna
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 1) {
        _fetchCallLogs();
      }
    });

    _fetchMyDetails();
    _listenToActiveChats();
  }

  // 🔥 Real-time Chat Name Listener
  void _listenToActiveChats() {
    _chatSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('active_chats')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        bool updated = false;
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final String? chatifyId = data['chatifyId']?.toString();
          final String? name = data['name']?.toString();
          
          if (chatifyId != null && name != null) {
            if (_nameCache[chatifyId] != name) {
              _nameCache[chatifyId] = name;
              updated = true;
            }
          }
        }
        if (updated) setState(() {}); // Sirf tabhi update karo jab naya naam mile
      }
    });
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

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
        if (myChatId != null) _fetchCallLogs();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _fetchCallLogs() async {
    if (myChatId == null || myJwt == null) return;
    try {
      final res = await http.get(
        Uri.parse("https://synnex.onrender.com/api/calls/$myChatId"),
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
      debugPrint("Error fetching calls: $e");
      if (mounted) setState(() => _isLoadingCalls = false);
    }
  }

  // 🔥 Ultra Safe Name Resolver
  String _getDisplayName(Map<String, dynamic> call) {
    final isOutgoing = call['callerId']?.toString() == myChatId;
    final targetId = (isOutgoing ? call['receiverId'] : call['callerId'])?.toString() ?? "";

    if (targetId.isEmpty) return "Unknown";

    // 1. First check background cache
    if (_nameCache.containsKey(targetId)) return _nameCache[targetId]!;

    // 2. Fallback to API data
    var rawName = isOutgoing ? call['receiverName'] : call['callerName'];
    if (rawName != null) {
      if (rawName is String) return rawName;
      if (rawName is Map) return rawName['name']?.toString() ?? "Unknown";
    }

    return "Unknown User";
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return "";
    try {
      return DateFormat('MMM d, h:mm a').format(DateTime.parse(dateStr).toLocal());
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Chats"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: "CHATS"), Tab(text: "CALLS")],
        ),
      ),
      body: _isLoadingDetails 
          ? const Center(child: CircularProgressIndicator()) 
          : TabBarView(
              controller: _tabController,
              children: [_buildChatListTab(), _buildCallHistoryTab()],
            ),
    );
  }

  Widget _buildChatListTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('active_chats')
          .orderBy('time', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No chats yet"));
        
        final chats = snapshot.data!.docs;
        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chat = chats[index].data() as Map<String, dynamic>;
            final name = chat['name']?.toString() ?? "User";
            final otherChatId = chat['chatifyId']?.toString();
            final lastMsg = chat['lastMessage']?.toString() ?? "";

            return ListTile(
              tileColor: Colors.white,
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: TextStyle(color: Colors.blue.shade900)),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                if (myChatId != null && otherChatId != null) {
                  List<String> ids = [myChatId!, otherChatId];
                  ids.sort();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChannelPage(
                    roomId: ids.join("___"),
                    me: myChatId!,
                    other: otherChatId,
                    otherName: name,
                    jwt: myJwt!,
                    myUid: myUid,
                    myName: myName ?? "Me",
                    otherUid: chats[index].id,
                  ))).then((_) => _fetchCallLogs());
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCallHistoryTab() {
    if (_isLoadingCalls) return const Center(child: CircularProgressIndicator());
    if (_calls.isEmpty) return _buildEmptyState(Icons.call_end_outlined, "No recent calls");

    return RefreshIndicator(
      onRefresh: _fetchCallLogs,
      child: ListView.builder(
        itemCount: _calls.length,
        itemBuilder: (context, index) {
          final call = _calls[index];
          final isOutgoing = call['callerId']?.toString() == myChatId;
          final status = call['status']?.toString().toLowerCase();
          final isVideo = call['type'] == 'video';
          
          IconData statusIcon = status == 'missed' ? Icons.call_missed : (isOutgoing ? Icons.call_made : Icons.call_received);
          Color statusColor = status == 'missed' ? Colors.red : (isOutgoing ? Colors.grey : Colors.green);

          return ListTile(
            tileColor: Colors.white,
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: Icon(isVideo ? Icons.videocam : Icons.call, color: Colors.blue.shade800),
            ),
            title: Text(_getDisplayName(call), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(_formatTime(call['timestamp']?.toString())),
              ],
            ),
            trailing: IconButton(
              icon: Icon(isVideo ? Icons.videocam : Icons.call, color: Colors.blue.shade800),
              onPressed: () {
                // TODO: Start new call logic
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}