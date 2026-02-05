import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/socket_service.dart';

// ==========================================
// 1. ALUMNI CHAT LIST PAGE (Ye Dashboard ke liye zaroori hai)
// ==========================================
class AlumniChatListPage extends StatefulWidget {
  const AlumniChatListPage({super.key});

  @override
  State<AlumniChatListPage> createState() => _AlumniChatListPageState();
}

class _AlumniChatListPageState extends State<AlumniChatListPage> {
  bool _isLoading = true;
  List<dynamic> _chatUsers = [];
  String? myJwt;
  String? myUid;
  String? myName;

  @override
  void initState() {
    super.initState();
    _loadUserAndChats();
  }

  Future<void> _loadUserAndChats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myJwt = prefs.getString('token');
      myUid = prefs.getString('uid');
      myName = prefs.getString('name');
    });

    if (myJwt != null) {
      _fetchChatList();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchChatList() async {
    try {
      // NOTE: Is URL ko apne backend ke 'Get All Users' route se replace karna
      final res = await http.get(
        Uri.parse("https://synnex.onrender.com/api/user/all"), 
        headers: {"Authorization": "Bearer $myJwt"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _chatUsers = data['users'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching chat list: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Alumni Chats"),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _chatUsers.isEmpty
          ? const Center(child: Text("No users found."))
          : ListView.builder(
              itemCount: _chatUsers.length,
              itemBuilder: (context, index) {
                final user = _chatUsers[index];
                final otherName = user['name'] ?? "Unknown";
                final otherUid = user['_id'] ?? "";

                if (otherUid == myUid) return const SizedBox.shrink();

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: Text(otherName.isNotEmpty ? otherName[0].toUpperCase() : "?"),
                    ),
                    title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Tap to chat"),
                    trailing: const Icon(Icons.chat_bubble_outline, color: Colors.indigo),
                    onTap: () {
                      // Room ID Logic
                      List<String> ids = [myUid!, otherUid];
                      ids.sort();
                      String roomId = ids.join("_");

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChannelPage(
                            roomId: roomId,
                            me: myUid!,
                            other: otherUid,
                            otherName: otherName,
                            jwt: myJwt!,
                            myUid: myUid!,
                            myName: myName ?? "Me",
                            otherUid: otherUid,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ==========================================
// 2. CHANNEL PAGE (Main Chat Screen)
// ==========================================
class ChannelPage extends StatefulWidget {
  final String roomId;
  final String me;
  final String other;
  final String otherName;
  final String jwt;
  final String myUid;
  final String myName;
  final String otherUid;

  const ChannelPage({
    super.key,
    required this.roomId,
    required this.me,
    required this.other,
    required this.otherName,
    required this.jwt,
    required this.myUid,
    required this.myName,
    required this.otherUid,
  });

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  final SocketService _socketService = SocketService();

  String get baseUrl => "https://synnex.onrender.com";

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _setupSocketListeners();
    
    // ✅ ERROR FIXED HERE: Added '?' before .emit
    // Agar socket connect nahi bhi hua, toh app crash nahi hoga
    _socketService.socket?.emit('join-room', widget.roomId);
  }

  Future<void> _fetchMessages() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/messages/${widget.roomId}"),
        headers: {"Authorization": "Bearer ${widget.jwt}"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['success'] == true) {
          if (mounted) {
            setState(() {
              _messages = List.from(data['messages'] ?? []);
              _isLoading = false;
            });
            _scrollToBottom();
          }
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching messages: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupSocketListeners() {
    _socketService.onReceiveMessage((data) {
      if (mounted) {
        setState(() {
          _messages.add({
            "senderId": data['senderId'],
            "text": data['message'] ?? data['text'] ?? "",
            "createdAt": DateTime.now().toString(),
          });
        });
        _scrollToBottom();
      }
    });
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _socketService.sendMessage(
      roomId: widget.roomId,
      receiverId: widget.other,
      message: text,
      senderId: widget.me,
    );

    if (mounted) {
      setState(() {
        _messages.add({
          "senderId": widget.me,
          "text": text,
          "createdAt": DateTime.now().toString(),
        });
        _msgController.clear();
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherName),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text("No messages yet. Say Hi! 👋"))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _messages.length,
                        padding: const EdgeInsets.all(10),
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['senderId'] == widget.me;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.indigo.shade600 : Colors.grey.shade300,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
                                  bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                msg['text'] ?? "",
                                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.indigo.shade800,
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}