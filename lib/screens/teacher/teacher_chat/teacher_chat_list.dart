import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

// ✅ Path check karlena apne project ke hisaab se
import 'package:synnex/screens/chat/channel_page.dart'; 

class TeacherChatListPage extends StatefulWidget {
  const TeacherChatListPage({super.key});

  @override
  State<TeacherChatListPage> createState() => _TeacherChatListPageState();
}

class _TeacherChatListPageState extends State<TeacherChatListPage> with SingleTickerProviderStateMixin {
  final String myUid = FirebaseAuth.instance.currentUser!.uid;
  late TabController _tabController;

  String? myChatId, myJwt, myName;
  bool loading = true;
  List<dynamic> _calls = [];
  bool _isLoadingCalls = true;

  // 🔥 POWERFUL CACHE: Background mein names store karne ke liye
  final Map<String, String> _nameCache = {};
  StreamSubscription? _chatSubscription;

  String get baseUrl => "https://synnex.onrender.com";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); 
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 1) {
        _fetchCallLogs();
      }
    });

    _fetchMyDetails();
    _listenToActiveChats(); // Background mein names load karo
  }

  // 🔥 SMART LISTENER: Active chats se names cache mein daalta hai
  void _listenToActiveChats() {
    _chatSubscription = FirebaseFirestore.instance
        .collection('users').doc(myUid).collection('active_chats')
        .snapshots().listen((snapshot) {
      if (mounted) {
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final String? cid = data['chatifyId']?.toString();
          final String? name = data['name']?.toString();
          if (cid != null && name != null) _nameCache[cid] = name;
        }
        setState(() {}); // UI update for names
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
      final doc = await FirebaseFirestore.instance.collection('teachers').doc(myUid).get();
      if (doc.exists && mounted) {
        setState(() {
          myJwt = doc.data()?['chatifyJwt']?.toString();
          myChatId = doc.data()?['chatifyUserId']?.toString();
          myName = doc.data()?['name']?.toString();
          loading = false;
        });
        if (myChatId != null) _fetchCallLogs();
      }
    } catch (e) {
      if(mounted) setState(() => loading = false);
    }
  }

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
            _isLoadingCalls = false;
          });
        }
      }
    } finally {
      if(mounted) setState(() => _isLoadingCalls = false);
    }
  }

  // 🔥 RESOLVE NAME: Pehle Cache phir API data
  String _resolveDisplayName(Map<String, dynamic> call) {
    final callerData = call['callerId'];
    final receiverData = call['receiverId'];
    final String callerMongoId = (callerData is Map) ? callerData['_id'] : callerData.toString();
    final isOutgoing = callerMongoId == myChatId;

    // 1. Target ID dhoondo
    final targetId = isOutgoing 
        ? ((receiverData is Map) ? receiverData['_id'] : receiverData.toString())
        : callerMongoId;

    // 2. Cache Check (Firestore names)
    if (_nameCache.containsKey(targetId)) return _nameCache[targetId]!;

    // 3. Fallback to API populated data
    if (isOutgoing && receiverData is Map) return receiverData['displayName'] ?? "User";
    if (!isOutgoing && callerData is Map) return callerData['displayName'] ?? "User";

    return "Unknown User";
  }

  String _formatChatTime(Timestamp? timestamp) {
    if (timestamp == null) return "";
    return DateFormat('hh:mm a').format(timestamp.toDate());
  }

  String _formatCallTime(String? dateStr) {
    if (dateStr == null) return "";
    try {
      return DateFormat('MMM d, h:mm a').format(DateTime.parse(dateStr).toLocal());
    } catch (e) { return ""; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Chats"),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: "CHATS"), Tab(text: "CALLS")],
        ),
      ),
      body: loading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [_buildChatListTab(), _buildCallHistoryTab()],
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal.shade800,
        child: const Icon(Icons.message, color: Colors.white),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Search feature coming soon!")),
        ),
      ),
    );
  }

  Widget _buildChatListTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(myUid).collection('active_chats').orderBy('time', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No chats yet"));
        final chats = snapshot.data!.docs;
        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chat = chats[index].data() as Map<String, dynamic>;
            final name = chat['name'] ?? "User";
            return ListTile(
              tileColor: Colors.white,
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade100, 
                child: Text(name[0].toUpperCase(), style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold)),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(chat['lastMessage'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(_formatChatTime(chat['time'])),
              onTap: () async {
                if (myChatId != null && myJwt != null) {
                  List<String> ids = [myChatId!, chat['chatifyId']];
                  ids.sort();
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => ChannelPage(
                    roomId: ids.join("___"), me: myChatId!, other: chat['chatifyId'], otherName: name, jwt: myJwt!,
                    myUid: myUid, myName: myName ?? "Teacher", otherUid: chats[index].id
                  )));
                  _fetchCallLogs();
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
    if (_calls.isEmpty) return const Center(child: Text("No recent calls"));

    return RefreshIndicator(
      onRefresh: _fetchCallLogs,
      child: ListView.builder(
        itemCount: _calls.length,
        itemBuilder: (context, index) {
          final call = _calls[index];
          final callerData = call['callerId'];
          final String callerMongoId = (callerData is Map) ? callerData['_id'] : callerData.toString();
          final isOutgoing = callerMongoId == myChatId;
          final status = call['status'];

          return ListTile(
            tileColor: Colors.white,
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: const Icon(Icons.person, color: Colors.teal),
            ),
            title: Text(_resolveDisplayName(call), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                Icon(
                  status == 'missed' ? Icons.call_missed : (isOutgoing ? Icons.call_made : Icons.call_received), 
                  size: 16, 
                  color: status == 'missed' ? Colors.red : Colors.green
                ),
                const SizedBox(width: 5),
                Text(_formatCallTime(call['createdAt'] ?? call['timestamp'])), 
              ],
            ),
            trailing: Icon(call['type'] == 'video' ? Icons.videocam : Icons.call, color: Colors.teal.shade800),
          );
        },
      ),
    );
  }
}