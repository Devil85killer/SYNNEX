import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // kIsWeb ke liye

// ✅ Import Path Check karlena
import 'package:SYNNEX/screens/chat/channel_page.dart'; 

class TeacherChatListPage extends StatefulWidget {
  const TeacherChatListPage({super.key});

  @override
  State<TeacherChatListPage> createState() => _TeacherChatListPageState();
}

class _TeacherChatListPageState extends State<TeacherChatListPage> with SingleTickerProviderStateMixin {
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

  // ✅ Sahi URL Logic
  String get baseUrl => kIsWeb ? "https://synnex.onrender.com" : "https://synnex.onrender.com";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); 
    
    // Tab change hone par calls refresh karo
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 1) {
        _fetchCallLogs();
      }
    });

    _fetchMyDetails();
  }

  // 1. TEACHER DETAILS
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
        
        if (myChatId != null) {
          _fetchCallLogs();
        } else {
           if (mounted) setState(() => _isLoadingCalls = false);
        }
      } else {
        if(mounted) setState(() { loading = false; _isLoadingCalls = false; });
      }
    } catch (e) {
      if(mounted) setState(() { loading = false; _isLoadingCalls = false; });
    }
  }

  // 2. FETCH CALLS
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
    } catch (e) {
      print("Error calls: $e");
    } finally {
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
      appBar: AppBar(
        title: const Text("Teacher Chats"),
        backgroundColor: Colors.teal.shade800,
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
      backgroundColor: Colors.grey.shade100,
      
      // ✅ BODY
      body: loading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildChatListTab(),
              _buildCallHistoryTab(),
            ],
          ),

      // 🔥 FLOATING ACTION BUTTON ADDED (Teacher Theme: Teal)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal.shade800,
        child: const Icon(Icons.message, color: Colors.white),
        onPressed: () {
          // TODO: Navigate to Search Users Page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("New Chat / Search feature coming soon!")),
          );
        },
      ),
    );
  }

  // 💬 TAB 1: CHAT LIST
  Widget _buildChatListTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(myUid).collection('active_chats').orderBy('time', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No chats yet"));
        }
        final chats = snapshot.data!.docs;
        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (ctx, i) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chat = chats[index].data() as Map<String, dynamic>;
            final otherUid = chats[index].id;
            return ListTile(
              tileColor: Colors.white,
              leading: CircleAvatar(backgroundColor: Colors.teal.shade100, child: const Icon(Icons.person, color: Colors.teal)),
              title: Text(chat['name'] ?? "User"),
              subtitle: Text(chat['lastMessage'] ?? ""),
              trailing: Text(_formatChatTime(chat['time'])),
              onTap: () async {
                if (myChatId != null && myJwt != null) {
                   List<String> ids = [myChatId!, chat['chatifyId']];
                   ids.sort();
                   
                   await Navigator.push(context, MaterialPageRoute(builder: (_) => ChannelPage(
                     roomId: ids.join("___"), me: myChatId!, other: chat['chatifyId'], otherName: chat['name'], jwt: myJwt!,
                     myUid: myUid, myName: myName ?? "Teacher", otherUid: otherUid
                   )));

                   _fetchCallLogs(); // Refresh calls on return
                }
              },
            );
          },
        );
      },
    );
  }

  // 📞 TAB 2: CALL HISTORY
  Widget _buildCallHistoryTab() {
    if (_isLoadingCalls) return const Center(child: CircularProgressIndicator());
    if (_calls.isEmpty) return const Center(child: Text("No recent calls"));

    return RefreshIndicator(
      onRefresh: _fetchCallLogs,
      child: ListView.builder(
        itemCount: _calls.length,
        itemBuilder: (context, index) {
          final call = _calls[index];
          final isOutgoing = call['callerId'] == myChatId;
          final status = call['status'];
          
          return ListTile(
            tileColor: Colors.white,
            leading: CircleAvatar(backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person, color: Colors.grey)),
            title: Text(isOutgoing ? (call['receiverName'] ?? "Unknown") : (call['callerName'] ?? "Unknown")),
            subtitle: Row(children: [
              Icon(status == 'missed' ? Icons.call_missed : (isOutgoing ? Icons.call_made : Icons.call_received), 
                   size: 16, color: status == 'missed' ? Colors.red : Colors.green),
              const SizedBox(width: 5),
              Text(_formatCallTime(call['timestamp']))
            ]),
            trailing: Icon(call['type'] == 'video' ? Icons.videocam : Icons.call, color: Colors.teal),
          );
        },
      ),
    );
  }
}