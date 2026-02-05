import 'dart:convert';
import 'package:flutter/foundation.dart'; // kIsWeb ke liye
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
  final String myUid = FirebaseAuth.instance.currentUser!.uid; // Firebase UID
  
  // Data State
  String? myChatId; // MongoDB User ID
  String? myJwt;
  List<dynamic> _calls = [];
  bool _isLoading = true;

  // ⚠️ Emulator: 10.67.251.188, Web: localhost
  // Agar phone pe chala rahe ho toh apne PC ka IP daalo (e.g. 192.168.1.5)
  String get baseUrl {
    if (kIsWeb) return "https://synnex.onrender.com";
    return "https://synnex.onrender.com"; 
  }

  @override
  void initState() {
    super.initState();
    _fetchMyDetailsAndCalls();
  }

  // 1. Get User Details then Calls
  Future<void> _fetchMyDetailsAndCalls() async {
    try {
      // Pehle apna Chat ID aur JWT nikalo (Assuming Alumni collection, change if Teacher)
      var doc = await FirebaseFirestore.instance.collection('alumni_users').doc(myUid).get();
      if (!doc.exists) {
        doc = await FirebaseFirestore.instance.collection('teachers').doc(myUid).get();
      }
      // Agar students bhi hain toh unka bhi check kar lo
      if (!doc.exists) {
        doc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      }

      if (doc.exists) {
        if (mounted) {
          setState(() {
            myJwt = doc.data()?['chatifyJwt'];
            myChatId = doc.data()?['chatifyUserId'];
          });
        }
        if (myChatId != null) {
          _fetchCallLogs();
        }
      }
    } catch (e) {
      print("Error details: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Fetch Logs from API
  Future<void> _fetchCallLogs() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/calls/$myChatId"),
        headers: {"Authorization": "Bearer $myJwt"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _calls = data['data'];
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching calls: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔥 FIXED DATE FORMATTER (WhatsApp Style)
  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final callDate = DateTime(date.year, date.month, date.day);

      if (callDate == today) {
        return "Today, ${DateFormat('h:mm a').format(date)}";
      } else if (callDate == yesterday) {
        return "Yesterday, ${DateFormat('h:mm a').format(date)}";
      }
      return DateFormat('MMMM d, h:mm a').format(date);
    } catch (e) { return ""; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calls"),
        backgroundColor: const Color(0xFF1976D2), // WhatsApp Green/Blue Theme
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _calls.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_ic_call, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      const Text("No recent calls", style: TextStyle(color: Colors.grey, fontSize: 18)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _calls.length,
                  itemBuilder: (context, index) {
                    final call = _calls[index];
                    
                    // Logic: Kaun Caller hai?
                    final bool amICaller = call['callerId'] == myChatId;
                    
                    // Naam kiska dikhana hai? (Agar main caller hu, toh receiver ka naam dikhao)
                    final String nameToShow = amICaller 
                        ? (call['receiverName'] ?? "Unknown") 
                        : (call['callerName'] ?? "Unknown");
                    
                    final String type = call['type'] ?? "audio";
                    final String status = call['status'] ?? "completed";

                    // Icons Logic (WhatsApp Style)
                    IconData arrowIcon;
                    Color arrowColor;

                    if (status == 'missed') {
                      arrowIcon = Icons.call_missed; // ↙️
                      arrowColor = Colors.red;
                    } else if (amICaller) {
                      // Maine call kiya (Outgoing)
                      arrowIcon = Icons.call_made; // ↗️
                      arrowColor = Colors.green;
                    } else {
                      // Mujhe call aaya (Incoming)
                      arrowIcon = Icons.call_received; // ↙️
                      arrowColor = Colors.green; 
                      if(status == 'rejected') arrowColor = Colors.red;
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        // Agar image URL hai toh wo lagao, nahi toh icon
                        child: const Icon(Icons.person, color: Colors.grey, size: 30),
                      ),
                      title: Text(
                        nameToShow,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: status == 'missed' ? Colors.red : Colors.black87,
                        ),
                      ),
                      
                      // 🔥 WHATSAPP STYLE SUBTITLE: [Icon] [Date/Time]
                      subtitle: Row(
                        children: [
                          Icon(arrowIcon, size: 16, color: arrowColor),
                          const SizedBox(width: 5),
                          Text(
                            _formatDateTime(call['timestamp']),
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      
                      trailing: IconButton(
                        icon: Icon(
                          type == 'video' ? Icons.videocam : Icons.call,
                          color: const Color(0xFF128C7E), // WhatsApp Teal Color
                        ),
                        onPressed: () {
                          // TODO: Implement redial logic here
                          print("Redialing $nameToShow...");
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add_call, color: Colors.white),
        onPressed: () {
          // Open Contact List to make a new call
        },
      ),
    );
  }
}