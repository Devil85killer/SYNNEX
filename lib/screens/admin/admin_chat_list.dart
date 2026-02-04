import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import 'package:college_app/helpers/chat_permission.dart';
import 'package:college_app/screens/chat/channel_page.dart';

class AlumniChatListPage extends StatelessWidget {
  const AlumniChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    final controller = StreamChannelListController(
      client: StreamChat.of(context).client,
      filter: Filter.in_('members', [myUid]),
      limit: 20,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumni Chats'),
      ),
      body: StreamChannelListView(
        controller: controller,
        onChannelTap: (channel) {
          final members = channel.state!.members;

          final other = members.firstWhere(
            (m) => m.userId != myUid,
            orElse: () => members.first,
          );

          final otherRole =
              other.user?.extraData['role']?.toString() ?? '';

          if (!ChatPermission.canChat(
            myRole: 'alumni',
            otherRole: otherRole,
          )) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chat not allowed')),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StreamChannel(
                channel: channel,
                child: const ChannelPage(),
              ),
            ),
          );
        },
      ),
    );
  }
}
