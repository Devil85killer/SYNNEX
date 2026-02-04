import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlumniCallPage extends StatelessWidget {
  final String receiverId;
  final String receiverName;

  const AlumniCallPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  void makeCall(bool isVideo) async {
    final uid = FirebaseFirestore.instance.app.auth().currentUser!.uid;

    final roomId = "call_${DateTime.now().millisecondsSinceEpoch}";

    // Save call log for admin
    FirebaseFirestore.instance.collection("call_logs").add({
      "callerId": uid,
      "callerName": "Alumni",
      "receiverId": receiverId,
      "receiverName": receiverName,
      "roomId": roomId,
      "time": DateTime.now(),
      "type": isVideo ? "video" : "audio",
    });

    // Join call
    var jitsi = JitsiMeet();
    await jitsi.join(
      JitsiMeetConferenceOptions(
        room: roomId,
        audioOnly: !isVideo,
        userDisplayName: "Alumni",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Call $receiverName")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.call),
            label: const Text("Audio Call"),
            onPressed: () => makeCall(false),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.videocam),
            label: const Text("Video Call"),
            onPressed: () => makeCall(true),
          ),
        ],
      ),
    );
  }
}
