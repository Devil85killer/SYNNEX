import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/channel_page.dart'; // Chat Import

class TeacherJobDetailPage extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const TeacherJobDetailPage({
    super.key,
    required this.jobId,
    required this.jobData,
  });

  // 💬 CHAT LOGIC (Teacher -> Alumni)
  void messageAlumni(BuildContext context) async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final posterUid = jobData['postedBy'];
    final posterName = jobData['postedByName'] ?? "Alumni";

    if (posterUid == null || posterUid == myUid) return;

    try {
      // 1. Teacher (My) Details
      final myDoc = await FirebaseFirestore.instance.collection('teachers').doc(myUid).get();
      final myChatId = myDoc.data()?['chatifyUserId'];
      final myJwt = myDoc.data()?['chatifyJwt'];

      // 2. Alumni Details
      final alumniDoc = await FirebaseFirestore.instance.collection('alumni_users').doc(posterUid).get();
      final alumniChatId = alumniDoc.data()?['chatifyUserId'];

      if (myChatId != null && myJwt != null && alumniChatId != null) {
        
        final List<String> ids = [myChatId, alumniChatId];
        ids.sort();
        final roomId = ids.join("__");

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChannelPage(
                roomId: roomId,
                me: myChatId,
                other: alumniChatId,
                otherName: posterName,
                jwt: myJwt,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Alumni not available for chat.")),
        );
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Details"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(jobData["title"] ?? "", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(jobData["company"] ?? "", style: const TextStyle(fontSize: 20, color: Colors.grey)),
            const SizedBox(height: 20),
            
            const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(jobData["description"] ?? ""),
            const SizedBox(height: 30),

            // 👇 MESSGAE BUTTON
            ElevatedButton.icon(
              onPressed: () => messageAlumni(context),
              icon: const Icon(Icons.message),
              label: const Text("Message Alumni"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}