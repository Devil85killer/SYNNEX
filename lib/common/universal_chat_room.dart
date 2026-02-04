// lib/common/universal_chat_room.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UniversalChatRoom extends StatefulWidget {
  final String peerUid;
  final String peerName;

  const UniversalChatRoom({
    super.key,
    required this.peerUid,
    required this.peerName,
  });

  @override
  State<UniversalChatRoom> createState() => _UniversalChatRoomState();
}

class _UniversalChatRoomState extends State<UniversalChatRoom> {
  final TextEditingController _ctrl = TextEditingController();
  final String myUid = FirebaseAuth.instance.currentUser!.uid;

  String get chatId {
    // deterministic id so both users share the same doc
    return (myUid.compareTo(widget.peerUid) < 0)
        ? "${myUid}_${widget.peerUid}"
        : "${widget.peerUid}_${myUid}";
  }

  Future<void> _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    await messagesRef.add({
      'from': myUid,
      'to': widget.peerUid,
      'text': text,
      'timestamp': DateTime.now(),
    });

    // update last message for quick listing (optional)
    await FirebaseFirestore.instance.collection('last_messages').doc(chatId).set({
      'from': myUid,
      'to': widget.peerUid,
      'text': text,
      'time': DateTime.now(),
      'peerName': widget.peerName,
    }, SetOptions(merge: true));

    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesStream,
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("No messages yet"));

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final bool isMe = data['from'] == myUid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue.shade200 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style: TextStyle(color: isMe ? Colors.black87 : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _sendMessage,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
