import 'dart:convert';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CallHistoryPage extends StatefulWidget {
  const CallHistoryPage({super.key});

  @override
  State<CallHistoryPage> createState() => _CallHistoryPageState();
}

class _CallHistoryPageState extends State<CallHistoryPage> {
  final String myUid = FirebaseAuth.instance.currentUser!.uid;
  String? myMongoId; // MongoDB ID
  String? myJwt;
  List<dynamic> _calls = [];
  bool _isLoading = true;

  String get baseUrl => "https://synnex.onrender.com";

  @override
  void initState() {
    super.initState();
    _fetchMyDetailsAndCalls();
  }

  Future<void> _fetchMyDetailsAndCalls() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('alumni_users').doc(myUid).get();
      if (!doc.exists) doc = await FirebaseFirestore.instance.collection('teachers').doc(myUid).get();
      if (!doc.exists) doc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();

      if (doc.exists && mounted) {
        setState(() {
          myJwt = doc.data()?['chatifyJwt'];
          myMongoId = doc.data()?['chatifyUserId'];
        });
        if (myMongoId != null) {
          _fetchCallLogs();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            _calls = data['calls'] ?? []; // ✅ Backend Key 'calls' hai
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (date.day == now.day) return "Today, ${DateFormat('h:mm a').format(date)}";
      return DateFormat('MMM d, h:mm a').format(date);
    } catch (e) { return ""; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calls"),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _calls.isEmpty
              ? const Center(child: Text("No recent calls"))
              : ListView.builder(
                  itemCount: _calls.length,
                  itemBuilder: (context, index) {
                    final call = _calls[index];
                    
                    // 🔥 PARSING LOGIC FIX FOR POPULATED OBJECTS
                    final callerObj = call['callerId']; // Object hai
                    final receiverObj = call['receiverId']; // Object hai
                    
                    // Check: Main Caller hu ya Receiver?
                    final bool amICaller = callerObj['_id'] == myMongoId;
                    
                    // Data Extract
                    final otherUser = amICaller ? receiverObj : callerObj;
                    final String name = otherUser['displayName'] ?? "Unknown";
                    final String? photo = otherUser['photoURL'];
                    
                    final String status = call['status'] ?? "ended";
                    final String type = call['type'] ?? "audio";
                    
                    // Icon Logic
                    IconData icon;
                    Color color;

                    if (status == 'missed') {
                      icon = Icons.call_missed;
                      color = Colors.red;
                    } else if (amICaller) {
                      icon = Icons.call_made;
                      color = Colors.green;
                    } else {
                      icon = Icons.call_received;
                      color = Colors.green;
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: (photo != null && photo != "") ? NetworkImage(photo) : null,
                        child: (photo == null || photo == "") ? const Icon(Icons.person, color: Colors.white) : null,
                      ),
                      title: Text(name, style: TextStyle(
                         fontWeight: FontWeight.bold,
                         color: status == 'missed' ? Colors.red : Colors.black
                      )),
                      subtitle: Row(
                        children: [
                          Icon(icon, size: 16, color: color),
                          const SizedBox(width: 5),
                          Text(_formatDateTime(call['startedAt'])), // ✅ 'startedAt' use karo
                        ],
                      ),
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