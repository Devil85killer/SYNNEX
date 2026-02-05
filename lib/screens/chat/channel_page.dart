import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji_picker; 
import 'package:intl/intl.dart'; 
import 'package:flutter/foundation.dart'; // kIsWeb check ke liye

// ✅ APNE PROJECT KE SAHI PATH CHECK KAR LENA
import '../../services/socket_service.dart';
import '../calling_screen.dart'; 

class ChannelPage extends StatefulWidget {
  final String roomId;
  final String me;
  final String other;
  final String otherName;
  final String jwt;
  final String? myUid;
  final String? myName;
  final String? otherUid;

  const ChannelPage({
    super.key,
    required this.roomId,
    required this.me,
    required this.other,
    required this.otherName,
    required this.jwt,
    this.myUid,
    this.myName,
    this.otherUid,
  });

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final SocketService socketService = SocketService(); // Singleton Instance
  final ImagePicker _picker = ImagePicker(); 
  
  String? _derivedChatifyId; 
  String? _socketRoomId; 
  bool _isLoading = true;
  String? _editingMessageId; 
  bool _showEmojiPicker = false; 
  final FocusNode _focusNode = FocusNode(); 
  
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  
  bool _isTyping = false;
  Timer? _typingTimer;
  bool _isOtherTyping = false; 

  final Color appPrimary = const Color(0xFF1976D2); 
  final Color bgCanvas = const Color(0xFFE5DDD5);
  final Color bubbleMy = const Color(0xFF1976D2);
  final Color bubbleOther = Colors.white;   
  final Color textMy = Colors.white;
  final Color textOther = Colors.black87;

  // ⚠️ BACKEND URL - Render wala link
  String get baseUrl => "https://synnex.onrender.com"; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
    
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showEmojiPicker = false;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordTimer?.cancel();
    _typingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    
    // Optional: Leave room on exit
    // if (_socketRoomId != null) {
    //   socketService.socket?.emit("leaveRoom", _socketRoomId);
    // }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _socketRoomId != null) {
      _markAsSeen(_socketRoomId!);
    }
  }

  void _initializeChat() async {
    _parseJwt();
    
    // ✅ ID CLEANING (Trimming & Lowercase)
    final myId = getSafeId(_derivedChatifyId ?? widget.me).trim();
    final otherId = getSafeId(widget.other).trim();
    
    // ✅ ROOM ID GENERATION (Consistent Logic)
    final List<String> ids = [myId, otherId];
    ids.sort(); // Sort karna zaroori hai taaki 'A_B' aur 'B_A' same room bane
    
    _socketRoomId = ids.join("___"); 
    final fallbackRoomId = ids.join("__"); // Backup for old format

    debugPrint("---------------------------------------");
    debugPrint("🔍 CHAT DEBUG:");
    debugPrint("👤 My ID: $myId");
    debugPrint("👤 Other ID: $otherId");
    debugPrint("🏠 Generated Room ID: $_socketRoomId");
    debugPrint("---------------------------------------");

    if (_socketRoomId != null) {
      // ✅ Join Room
      socketService.joinRoom(_socketRoomId!);
      
      // ✅ Listeners
      socketService.onReceiveMessage(_onMessageReceived);
      
      socketService.socket?.on("typing", (data) {
         if (data == _socketRoomId && mounted) setState(() => _isOtherTyping = true);
      });
      socketService.socket?.on("stopTyping", (data) {
         if (data == _socketRoomId && mounted) setState(() => _isOtherTyping = false);
      });

      // ✅ FIX: Ye wala code aadha tha, maine pura kar diya
      socketService.socket?.on("messageStatusUpdate", (data) {
        if (!mounted) return;
        setState(() {
          // Single Message Update
          final index = _messages.indexWhere((m) => m["_id"] == data["messageId"]);
          if (index != -1) {
            _messages[index]["status"] = data["status"];
          }
          // Bulk Seen Update
          if (data["status"] == "seen") {
             for (var msg in _messages) {
               if (getSafeId(msg["senderId"]) == myId) {
                 msg["status"] = "seen";
               }
             }
          }
        });
      });
      
      await _ensureChatExists(otherId);
      await _smartLoadHistory(_socketRoomId!, fallbackRoomId);
      
      _markAsSeen(_socketRoomId!);
    }
  }

  void _markAsSeen(String roomId) {
    final myId = getSafeId(_derivedChatifyId ?? widget.me);
    socketService.socket?.emit("markAsSeen", {
      "roomId": roomId,
      "userId": myId,
    });
  }

  Future<void> _ensureChatExists(String receiverId) async {
    try {
      await http.post(Uri.parse("$baseUrl/api/chats"),
        headers: {"Authorization": "Bearer ${widget.jwt}", "Content-Type": "application/json"},
        body: jsonEncode({"receiverId": receiverId}), 
      );
    } catch (e) { print("Chat Check Error: $e"); }
  }

  Future<void> _smartLoadHistory(String primaryId, String backupId) async {
    bool success = await _fetchHistory(primaryId);
    if (!success && _messages.isEmpty) {
        print("⚠️ Primary Room ID empty, trying fallback...");
        await _fetchHistory(backupId);
    }
  }

  Future<bool> _fetchHistory(String targetRoomId) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/messages/$targetRoomId"),
        headers: {"Authorization": "Bearer ${widget.jwt}", "Content-Type": "application/json"},
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded["success"] == true) {
          final List list = decoded["data"] ?? [];
          if (mounted) {
            setState(() {
              _messages.clear();
              _messages.addAll(list.map((m) => {
                "_id": m["_id"], 
                "message": m["message"],
                "type": m["type"] ?? "text", 
                "senderId": getSafeId(m["senderId"]), 
                "time": m["createdAt"] ?? DateTime.now().toString(),
                "status": m["status"] ?? "sent"
              }));
              _isLoading = false;
            });
            _scrollToBottom();
          }
          return true;
        }
      }
    } catch (e) { print("Error fetching history: $e"); }
    return false;
  }

  void _parseJwt() {
    try {
      if (widget.jwt.isEmpty) return;
      final parts = widget.jwt.split('.');
      if (parts.length != 3) return;
      final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      _derivedChatifyId = payload['chatifyUserId']?.toString();
    } catch (e) { print("JWT Error: $e"); }
  }

  String getSafeId(dynamic id) {
    if (id == null) return "";
    if (id is Map) return id['chatifyUserId']?.toString().trim() ?? "";
    return id.toString().trim();
  }

  void _onMessageReceived(dynamic data) {
    if (!mounted) return;
    
    final incomingSenderId = getSafeId(data["senderId"]);
    final myId = getSafeId(_derivedChatifyId ?? widget.me);

    if (incomingSenderId == myId) return; 

    setState(() {
      _messages.add({
        "_id": data["_id"], 
        "message": data["message"],
        "type": data["type"] ?? "text",
        "senderId": incomingSenderId,
        "time": DateTime.now().toString(),
        "status": "seen"
      });
      _isOtherTyping = false;
    });
    _scrollToBottom();
    
    if (_socketRoomId != null) {
      _markAsSeen(_socketRoomId!);
    }
  }

  void _onTextChanged(String text) {
    setState(() {}); 
    if (_socketRoomId == null) return;
    if (!_isTyping) {
      _isTyping = true;
      socketService.socket?.emit("typing", _socketRoomId);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1000), () {
      _isTyping = false;
      socketService.socket?.emit("stopTyping", _socketRoomId);
    });
  }

  void _handleSendOrUpdate() {
    if (_isRecording) {
      _stopRecording(); 
      return;
    }
    if (_controller.text.trim().isEmpty) return;

    if (_editingMessageId != null) {
      _editMessage();
    } else {
      _sendMessage(_controller.text.trim(), "text");
    }
  }

  void _sendMessage(String content, String type) {
    if (content.isEmpty || _socketRoomId == null) return;
    final myId = getSafeId(_derivedChatifyId ?? widget.me);

    final tempId = DateTime.now().toString(); 
    
    // UI Update (Optimistic)
    setState(() {
      _messages.add({
        "_id": tempId,
        "message": content,
        "type": type,
        "senderId": myId,
        "time": DateTime.now().toString(),
        "status": "sent"
      });
    });

    // Socket Emit
    socketService.sendMessage(
        roomId: _socketRoomId!, 
        message: content, 
        senderId: myId, 
        receiverId: widget.other
    );

    // API Call (Backup & Notification)
    http.post(Uri.parse("$baseUrl/api/messages"),
      headers: {"Authorization": "Bearer ${widget.jwt}", "Content-Type": "application/json"},
      body: jsonEncode({
        "roomId": _socketRoomId, 
        "message": content, 
        "type": type,
        "senderName": widget.myName ?? "Unknown User", 
        "receiverName": widget.otherName 
      })
    );
    
    _updateFirestoreList(type == 'image' ? '📷 Photo' : (type == 'audio' ? '🎤 Voice Message' : content));
    _controller.clear();
    setState(() {}); 
    _scrollToBottom();
  }

  void _openVideoCall() {
    if (socketService.socket == null || !socketService.socket!.connected) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat Disconnected. Reconnecting...")));
       return;
    }
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => CallingScreen(
          targetId: widget.other, 
          name: widget.otherName,
          callType: 'video', 
          socket: socketService.socket,
        )
      )
    );
  }

  void _openAudioCall() {
    if (socketService.socket == null || !socketService.socket!.connected) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat Disconnected. Reconnecting...")));
       return;
    }
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => CallingScreen(
          targetId: widget.other, 
          name: widget.otherName,
          callType: 'audio',
          socket: socketService.socket,
        )
      )
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordDuration = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration++;
      });
    });
  }

  void _stopRecording() {
    _recordTimer?.cancel();
    setState(() {
      _isRecording = false;
    });
    _sendMessage("Audio Duration: ${_formatDuration(_recordDuration)}", "audio");
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(source: source, imageQuality: 50);
      if (photo != null) {
        List<int> imageBytes = await photo.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        _sendMessage(base64Image, "image");
      }
    } catch (e) { print("Image Pick Error: $e"); }
  }

  Future<void> _editMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _editingMessageId == null) return;
    setState(() {
      final index = _messages.indexWhere((m) => m["_id"] == _editingMessageId);
      if (index != -1) _messages[index]["message"] = text;
      _editingMessageId = null;
      _controller.clear();
    });
    try {
      await http.put(Uri.parse("$baseUrl/api/messages/$_editingMessageId"),
          headers: {"Authorization": "Bearer ${widget.jwt}", "Content-Type": "application/json"},
          body: jsonEncode({"message": text})
      );
    } catch (e) { print("Edit failed: $e"); }
  }

  Future<void> _deleteMessage(String msgId) async {
    setState(() {
      _messages.removeWhere((m) => m["_id"] == msgId);
    });
    try {
      await http.delete(Uri.parse("$baseUrl/api/messages/$msgId"),
          headers: {"Authorization": "Bearer ${widget.jwt}", "Content-Type": "application/json"},
      );
    } catch (e) { print("Delete failed: $e"); }
  }

  Future<void> _updateFirestoreList(String msg) async {
    if (widget.myUid == null || widget.otherUid == null) return;
    final ts = FieldValue.serverTimestamp();
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.myUid).collection('active_chats').doc(widget.otherUid).set({
        'name': widget.otherName, 'lastMessage': msg, 'time': ts, 'chatifyId': widget.other, 'unread': false
      }, SetOptions(merge: true));
    } catch (e) { print("Error Syncing Firestore: $e"); }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent + 100, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _showMessageOptions(Map<String, dynamic> msg, bool isMe) {
    if (!isMe) return; 
    showModalBottomSheet(context: context, builder: (context) {
      return Wrap(children: [
        if (msg["type"] == "text")
        ListTile(leading: const Icon(Icons.edit), title: const Text('Edit'), onTap: () {
          Navigator.pop(context);
          setState(() { _editingMessageId = msg["_id"]; _controller.text = msg["message"]; });
        }),
        ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Delete'), onTap: () {
          Navigator.pop(context); _deleteMessage(msg["_id"]);
        }),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final myId = getSafeId(_derivedChatifyId ?? widget.me);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leadingWidth: 40,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            const CircleAvatar(radius: 18, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 24, color: Colors.white)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (_isOtherTyping)
                  const Text("typing...", style: TextStyle(fontSize: 12, color: Colors.white, fontStyle: FontStyle.italic))
                else
                  const Text("Online", style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70)),
              ],
            ),
          ],
        ),
        backgroundColor: appPrimary, 
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: _openVideoCall), 
          IconButton(icon: const Icon(Icons.call), onPressed: _openAudioCall),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      backgroundColor: bgCanvas, 
      body: WillPopScope(
        onWillPop: () async {
          if (_showEmojiPicker) { setState(() => _showEmojiPicker = false); return false; }
          return true;
        },
        child: Column(
          children: [
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isMe = getSafeId(msg["senderId"]) == myId;
                      return GestureDetector(
                        onLongPress: () => _showMessageOptions(msg, isMe),
                        child: _buildBubble(msg, isMe),
                      );
                    },
                  ),
            ),
            _buildInputArea(),
            if (_showEmojiPicker) SizedBox(
              height: 250,
              child: emoji_picker.EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _controller.text = _controller.text + emoji.emoji;
                  _onTextChanged(_controller.text); 
                },
                config: emoji_picker.Config(
                  columns: 7, emojiSizeMax: 32, verticalSpacing: 0, horizontalSpacing: 0, gridPadding: EdgeInsets.zero,
                  initCategory: emoji_picker.Category.RECENT, bgColor: const Color(0xFFF2F2F2), indicatorColor: appPrimary,
                  iconColor: Colors.grey, iconColorSelected: appPrimary, backspaceColor: appPrimary, skinToneDialogBgColor: Colors.white,
                  skinToneIndicatorColor: Colors.grey, enableSkinTones: true, recentsLimit: 28,
                  categoryIcons: const emoji_picker.CategoryIcons(), buttonMode: emoji_picker.ButtonMode.MATERIAL,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ BUBBLE WIDGET (Fix: Status Icons)
  Widget _buildBubble(Map<String, dynamic> msg, bool isMe) {
    bool isImage = msg["type"] == "image";
    bool isAudio = msg["type"] == "audio";
    bool isCallLog = msg["type"] == "call_log";

    if (isCallLog) {
       return Center(
         child: Container(
           margin: const EdgeInsets.symmetric(vertical: 8),
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
           decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(20)),
           child: Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               const Icon(Icons.call_end, size: 16, color: Colors.black54),
               const SizedBox(width: 5),
               Text(msg["message"], style: const TextStyle(fontSize: 12, color: Colors.black87)),
             ],
           ),
         ),
       );
    }

    String timeStr = "";
    try { 
      final dt = DateTime.parse(msg["time"]).toLocal(); 
      timeStr = DateFormat('h:mm a').format(dt); 
    } catch(e) { timeStr = ""; }

    IconData statusIcon = Icons.check; 
    Color statusColor = Colors.white70;

    if (msg["status"] == "delivered") {
      statusIcon = Icons.done_all; 
      statusColor = Colors.white70;
    } else if (msg["status"] == "seen") {
      statusIcon = Icons.done_all; 
      statusColor = Colors.lightBlueAccent; 
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isMe ? bubbleMy : bubbleOther, 
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isImage) 
              ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(base64Decode(msg["message"]), errorBuilder: (c,e,s) => const Icon(Icons.broken_image)))
            else if (isAudio)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                width: 150,
                child: Row(children: [Icon(Icons.play_arrow, color: isMe?Colors.white:Colors.black), const SizedBox(width: 5), Text(msg["message"] ?? "Audio", style: TextStyle(fontWeight: FontWeight.bold, color: isMe?Colors.white:Colors.black))]),
              )
            else
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text(msg["message"] ?? "", style: TextStyle(fontSize: 16, color: isMe ? textMy : textOther))),
            
            Padding(
              padding: const EdgeInsets.only(right: 5, bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(timeStr, style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey.shade600)),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(statusIcon, size: 16, color: statusColor),
                  ]
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
              child: _isRecording 
              ? Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.red, size: 24),
                    const SizedBox(width: 10),
                    Text("Recording ${_formatDuration(_recordDuration)}", style: const TextStyle(color: Colors.red, fontSize: 16)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () {
                      _recordTimer?.cancel(); setState(() => _isRecording = false);
                    }),
                  ],
                ) 
              : Row(
                  children: [
                    IconButton(icon: Icon(_showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined, color: Colors.grey), onPressed: () {
                      setState(() { 
                          if(_showEmojiPicker) _focusNode.requestFocus(); else FocusScope.of(context).unfocus();
                          _showEmojiPicker = !_showEmojiPicker; 
                      });
                    }),
                    Expanded(child: TextField(
                      controller: _controller, focusNode: _focusNode,
                      onChanged: _onTextChanged, 
                      decoration: const InputDecoration(hintText: "Type a message", border: InputBorder.none),
                      minLines: 1, maxLines: 4,
                    )),
                    IconButton(icon: const Icon(Icons.attach_file, color: Colors.grey), onPressed: () => _pickImage(ImageSource.gallery)),
                    IconButton(icon: const Icon(Icons.camera_alt, color: Colors.grey), onPressed: () => _pickImage(ImageSource.camera)),
                    if (_controller.text.isEmpty)
                      IconButton(icon: const Icon(Icons.mic, color: Colors.grey), onPressed: _startRecording),
                  ],
                ),
            ),
          ),
          const SizedBox(width: 8),
          if (_controller.text.isNotEmpty || _isRecording)
            GestureDetector(
              onTap: _handleSendOrUpdate,
              child: CircleAvatar(
                radius: 24,
                backgroundColor: appPrimary,
                child: Icon(_isRecording ? Icons.stop : Icons.send, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}