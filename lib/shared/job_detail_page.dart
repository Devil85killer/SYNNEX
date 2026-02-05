import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:synnex/screens/chat/common_chat_room.dart';

class JobDetailPage extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const JobDetailPage({
    super.key,
    required this.jobId,
    required this.jobData,
  });

  /// ✅ OPEN ZEGO CHAT (NO FIRESTORE)
  void openChat(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final otherUid = jobData["postedBy"];
    final otherName = jobData["postedByName"] ?? "User";

    if (otherUid == null || otherUid == myUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot open chat")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommonChatRoom(
          peerUserId: otherUid,
          peerName: otherName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = jobData["title"] ?? "";
    final company = jobData["company"] ?? "";
    final location = jobData["location"] ?? "";
    final skills = jobData["skillsRequired"] ?? "";
    final description = jobData["description"] ?? "";
    final postedByName = jobData["postedByName"] ?? "Unknown User";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Details"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  "Posted by: $postedByName",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18),
                const SizedBox(width: 4),
                Text(location),
              ],
            ),
            const SizedBox(height: 10),
            Text("Company: $company"),
            const SizedBox(height: 10),
            Text("Skills: $skills"),
            const SizedBox(height: 20),
            Text(description, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => openChat(context),
                icon: const Icon(Icons.message),
                label: const Text("Message"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
