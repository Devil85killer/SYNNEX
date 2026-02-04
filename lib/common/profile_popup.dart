// lib/common/profile_popup.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/universal_chat_room.dart'; // relative import

Future<void> showProfilePopup({
  required BuildContext context,
  required String peerUid,
  required String peerName,
  String? photoUrl,
}) {
  return showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Text(peerName.isNotEmpty ? peerName[0].toUpperCase() : "?",
                        style: const TextStyle(fontSize: 28, color: Colors.white))
                    : null,
                backgroundColor: Colors.blue,
              ),
              const SizedBox(height: 12),
              Text(peerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text("Message"),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UniversalChatRoom(peerUid: peerUid, peerName: peerName),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      // OPTIONAL: open full profile page (alumni/student/teacher)
                      // Example: open Firestore profile if you want:
                      final doc = await FirebaseFirestore.instance.collection('alumni_users').doc(peerUid).get();
                      if (doc.exists) {
                        final data = doc.data()!;
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(data['name'] ?? peerName),
                            content: Text("Batch: ${data['batch'] ?? '-'}\nCompany: ${data['company'] ?? '-'}"),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile not available")));
                      }
                    },
                    child: const Text("View Profile"),
                  )
                ],
              )
            ],
          ),
        ),
      );
    },
  );
}
