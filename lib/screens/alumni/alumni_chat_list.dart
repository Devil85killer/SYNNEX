import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../screens/chat/channel_page.dart'; // ✅ Chat Room Import

class AlumniChatListPage extends StatefulWidget {
  const AlumniChatListPage({super.key});

  @override
  State<AlumniChatListPage> createState() => _AlumniChatListPageState();
}

class _AlumniChatListPageState extends State<AlumniChatListPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  // Current User Info
  String? myUid;
  String? myName;
  String? myChatifyId;
  String? myJwt;

  @override
  void initState() {
    super.initState();
    _fetchMyDetails();
  }

  // 1. Apni details fetch karo (Taaki chat room mein bhej sakein)
  Future<void> _fetchMyDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('alumni_users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          myUid = user.uid;
          myName = doc.data()?['name'] ?? "Alumni";
          myChatifyId = doc.data()?['chatifyUserId']; // Zaroori hai
          myJwt = doc.data()?['chatifyJwt'];          // Zaroori hai
        });
      }
    }
  }

  // 2. Chat Room kholne ka logic
  void _openChat(DocumentSnapshot userDoc) {
    if (myChatifyId == null || myJwt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connecting to chat... please wait")),
      );
      return;
    }

    final otherData = userDoc.data() as Map<String, dynamic>;
    final otherChatifyId = otherData['chatifyUserId'];
    final otherName = otherData['name'] ?? "User";
    final otherUid = userDoc.id;

    if (otherChatifyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This user is not registered for chat yet.")),
      );
      return;
    }

    // Room ID Logic (Unique per pair)
    final List<String> ids = [myChatifyId!, otherChatifyId];
    ids.sort(); 
    final roomId = ids.join("_");

    // Navigate to ChannelPage (Jo code tumne bheja tha)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChannelPage(
          roomId: roomId,
          me: myChatifyId!,
          other: otherChatifyId,
          otherName: otherName,
          jwt: myJwt!,
          myUid: myUid!,
          myName: myName!,
          otherUid: otherUid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        backgroundColor: Colors.blue, 
      ),
      // Example: Showing Teachers to chat with
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('teachers').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs;
          
          if (users.isEmpty) {
            return const Center(child: Text("No users found to chat."));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;
              final name = data['name'] ?? "Unknown";
              final email = data['email'] ?? "";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(name[0].toUpperCase()),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(email),
                  trailing: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                  onTap: () => _openChat(user),
                ),
              );
            },
          );
        },
      ),
    );
  }
}