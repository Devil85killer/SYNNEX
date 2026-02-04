import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

// ✅ Make sure ChannelPage is imported
import '../chat/channel_page.dart'; 

class CommonJobFeedPage extends StatelessWidget {
  const CommonJobFeedPage({super.key});

  // 🔹 SMART CHAT LOGIC (Handles Student & Teacher) 🧠
  void _messagePoster(BuildContext context, String? posterUid, String? posterName) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    // 1. Basic Validation
    if (myUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: You are not logged in")));
      return;
    }

    if (posterUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Cannot identify job poster")));
      return;
    }

    if (posterUid == myUid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You cannot message yourself!")));
      return;
    }

    try {
      // 🕵️‍♂️ STEP 2: Identify 'Who am I?' (Student or Teacher)
      String? myJwt;
      String? myChatId;
      String? myName; // Needed for Chat List

      // Check Students Collection
      var doc = await FirebaseFirestore.instance.collection('students').doc(myUid).get();
      if (doc.exists) {
        final data = doc.data();
        myJwt = data?['chatifyJwt']?.toString();
        myChatId = data?['chatifyUserId']?.toString();
        myName = data?['name']?.toString();
      } else {
        // Check Teachers Collection
        doc = await FirebaseFirestore.instance.collection('teachers').doc(myUid).get();
        if (doc.exists) {
          final data = doc.data();
          myJwt = data?['chatifyJwt']?.toString();
          myChatId = data?['chatifyUserId']?.toString();
          myName = data?['name']?.toString();
        }
      }

      // If user not found or chat disabled
      if (myChatId == null || myJwt == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chat not enabled. Please Logout & Login again.")),
        );
        return;
      }

      // 🕵️‍♂️ STEP 3: Get Alumni (Poster) Details
      final alumniDoc = await FirebaseFirestore.instance.collection('alumni_users').doc(posterUid).get();
      final alumniChatId = alumniDoc.data()?['chatifyUserId']?.toString();
      
      if (alumniChatId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recruiter has not activated chat yet.")));
        return;
      }

      // 🚀 STEP 4: Open Chat Screen (Passing ALL Data for List Update)
      // Room ID = Alphabetical Sort of IDs
      final List<String> ids = [myChatId!, alumniChatId];
      ids.sort(); 
      final roomId = ids.join("__");

      if (context.mounted) {
        print("🚀 Opening Chat Room: $roomId");
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChannelPage(
              // Core Chat Data
              roomId: roomId,
              me: myChatId!,
              other: alumniChatId,
              otherName: posterName ?? "Recruiter",
              jwt: myJwt!,
              
              // 🔥 Extra Data for 'Active Chat List' Logic
              myUid: myUid,            // Student/Teacher Firebase UID
              myName: myName ?? "User", // Student/Teacher Name
              otherUid: posterUid,      // Alumni Firebase UID
            ),
          ),
        );
      }
    } catch (e) {
      print("❌ Chat Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error opening chat")));
    }
  }

  // 🔹 DELETE JOB (Owner Only)
  void _deleteJob(BuildContext context, String jobId) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job Deleted Successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete job")));
    }
  }

  // 🔹 OPEN LINK
  void _launchURL(String? url) async {
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Feed 💼"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade100,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .orderBy('postedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No Jobs Posted Yet", style: TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }

          final jobs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index].data() as Map<String, dynamic>;
              final jobId = jobs[index].id;
              
              // Safe Data Extraction
              final postedBy = job['postedBy']?.toString();
              final posterName = job['postedByName']?.toString() ?? "Recruiter";
              final isMyPost = (myUid != null && postedBy == myUid);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              job['title']?.toString() ?? "Job Title",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (isMyPost)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteJob(context, jobId),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      
                      // Company
                      Text(
                        job['company']?.toString() ?? "Company Name",
                        style: TextStyle(fontSize: 16, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),

                      // Details
                      Text(
                        "📍 ${job['location']?.toString() ?? 'Remote'}  |  💰 ${job['salary']?.toString() ?? 'Not disclosed'}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        job['description']?.toString() ?? "No description", 
                        maxLines: 3, 
                        overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 15),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _launchURL(job['applyLink']?.toString()),
                              child: const Text("Apply Now"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          
                          // 🔥 MESSAGE BUTTON (Works for Student AND Teacher)
                          if (!isMyPost)
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                label: const Text("Message"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _messagePoster(context, postedBy, posterName),
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}