import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCallLogsPage extends StatelessWidget {
  const AdminCallLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📞 All Call Logs",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("call_logs")
                    .orderBy("timestamp", descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final logs = snap.data!.docs;

                  if (logs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No calls made yet.",
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final data = logs[index].data() as Map<String, dynamic>;

                      final callType = data["callType"] ?? "unknown";
                      final caller = data["callerDisplay"] ?? data["callerUid"];
                      final receiver = data["receiverDisplay"] ?? data["receiverUid"];
                      final date = (data["timestamp"] as Timestamp).toDate();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            callType.contains("video")
                                ? Icons.videocam
                                : Icons.call,
                            color: callType.contains("video")
                                ? Colors.red
                                : Colors.green,
                            size: 30,
                          ),
                          title: Text("$caller ➜ $receiver"),
                          subtitle: Text(
                            "$callType call\n${date.toLocal()}",
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
