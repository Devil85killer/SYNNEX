import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/channel_page.dart'; // Tera Chat Screen

class StudentJobDetailPage extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const StudentJobDetailPage({
    super.key,
    required this.jobId,
    required this.jobData,
  });

  // 🔗 Apply Link Open karne ke liye
  void openApplyLink(BuildContext context) async {
    final url = jobData["applyLink"];
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Apply link not available")),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open link")),
      );
    }
  }

  // 💬 CHAT LOGIC (Student -> Alumni)
  void messageRecruiter(BuildContext context) async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final posterUid = jobData['postedBy'];
    final posterName = jobData['postedByName'] ?? "Recruiter";

    if (posterUid == null || posterUid == myUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot message yourself!")),
      );
      return;
    }

    try {
      // 1. Apani (Student) Details Nikalo (JWT Token ke liye)
      final myDoc = await FirebaseFirestore.instance.collection('students').doc(myUid).get();
      final myChatId = myDoc.data()?['chatifyUserId'];
      final myJwt = myDoc.data()?['chatifyJwt'];

      // 2. Alumni (Recruiter) Details Nikalo
      final alumniDoc = await FirebaseFirestore.instance.collection('alumni_users').doc(posterUid).get();
      final alumniChatId = alumniDoc.data()?['chatifyUserId'];

      // 3. Check karo dono exist karte hain ya nahi
      if (myChatId != null && myJwt != null && alumniChatId != null) {
        
        // Room ID banao (Sorted IDs)
        final List<String> ids = [myChatId, alumniChatId];
        ids.sort(); 
        final roomId = ids.join("__");

        // Chat Page Kholo
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
          const SnackBar(content: Text("Recruiter is not active on Chat yet.")),
        );
      }
    } catch (e) {
      print("Chat Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error opening chat")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(jobData["title"] ?? "Job Details"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (jobData["imageUrl"] != null)
              Image.network(jobData["imageUrl"], height: 200, width: double.infinity, fit: BoxFit.cover),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(jobData["title"] ?? "", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(jobData["company"] ?? "", style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 20),
                  
                  const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(jobData["description"] ?? ""),
                  const SizedBox(height: 10),

                  // 👇 ACTION BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => openApplyLink(context),
                          child: const Text("Apply Now"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => messageRecruiter(context), // 🔥 Chat Function
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          icon: const Icon(Icons.chat),
                          label: const Text("Message"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}