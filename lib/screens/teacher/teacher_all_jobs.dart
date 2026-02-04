import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../chat/common_chat_room.dart';

class StudentJobFeedPage extends StatelessWidget {
  const StudentJobFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Feed 🧑‍💻"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("jobs")
            .orderBy("postedAt", descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobs = snap.data!.docs;

          if (jobs.isEmpty) {
            return const Center(child: Text("No Jobs Posted Yet"));
          }

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index].data() as Map<String, dynamic>;
              final jobId = jobs[index].id;

              final postedBy = job["postedBy"];
              final postedByName = job["postedByName"] ?? "Unknown User";

              return Card(
                margin: const EdgeInsets.all(12),
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // IMAGE
                    if (job["imageUrl"] != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: Image.network(
                          job["imageUrl"],
                          height: 180,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job["title"] ?? "",
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),

                          Text(job["company"] ?? "",
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 16)),

                          const SizedBox(height: 10),

                          // ⭐ POSTED BY (CLICKABLE → CHAT)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AlumniChatRoomPage(
                                    peerUid: postedBy,
                                    peerName: postedByName,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.person,
                                    color: Colors.blue, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  "Posted by: $postedByName",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text("Location: ${job["location"]}"),
                          Text("Skills: ${job["skillsRequired"]}"),

                          const SizedBox(height: 15),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // ⭐ MESSAGE BUTTON
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CommonChatRoom(
                                        chatId: "$postedBy-${FirebaseAuth.instance.currentUser!.uid}",
                                        peerUid: postedBy, 
                                        peerName: postedByName,
                                      ),
                                    ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text("Message"),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
