import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; 
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji_picker; 
import 'package:intl/intl.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 

// ✅ IMPORTS
import '../services/socket_service.dart';
import '../services/call_service.dart';
import 'video_call_screen.dart'; // Ya CallingScreen, jo bhi file name ho

class ChannelPage extends StatefulWidget {
  final String roomId;
  final String me; // MongoDB ID of current user
  final String other; // MongoDB ID of other user
  final String otherName;
  final String jwt;
  final String? myUid; // Firebase UID
  final String? myName;
  final String? otherUid; // Firebase UID of other user

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
  final SocketService socketService = SocketService(); 
  final ImagePicker _picker = ImagePicker(); 
  
  String? _socketRoomId; 
  bool _isLoading = true;
  String? _editingMessageId; 
  bool _showEmojiPicker = false; 
  final FocusNode _focusNode = FocusNode(); 
  
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  bool _isOtherTyping = false; 
  bool _isTyping = false;
  Timer? _typingTimer;

  // WhatsApp Colors
  final Color appPrimary = const Color(0xFF075E54); 
  final Color bgCanvas = const Color(0xFFE5DDD5);   
  final Color bubbleMy = const Color(0xFFDCF8C6);   
  final Color bubbleOther = Colors.white;   
  final Color textMy = Colors.black87;              
  final Color textOther = Colors.black87;

  // ⚠️ BACKEND URL
  String get baseUrl => "https://synnex.onrender.com"; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
    
    // 🔥 AUTO-REJOIN LOGIC
    socketService.socket?.on('connect', (_) {
      if (_socketRoomId != null) {
        socketService.joinRoom(_socketRoomId!);
      }
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showEmojiPicker = false);
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
    super.dispose();
  }

  void _initializeChat() async {
    // Room ID Logic: Sorted IDs se room banta hai taaki unique rahe
    final List<String> ids = [widget.me, widget.other];
    ids.sort(); 
    _socketRoomId = ids.join("___"); 

    if (_socketRoomId != null) {
      print("✅ Joining Room: $_socketRoomId");

      // 1. Join Room
      socketService.joinRoom(_socketRoomId!);
      
      // 2. Listeners Setup
      socketService.onReceiveMessage(_onMessageReceived);
      
      // 🔵 BLUE TICKS LISTENER
      socketService.socket?.on("messages_seen", (data) {
        if (data['roomId'] == _socketRoomId) {
           if(mounted) {
             setState(() {
               for (var msg in _messages) {
                 if (msg['senderId'] == widget.me && msg['status'] != 'seen') {
                   msg['status'] = 'seen';
                 }
               }
             });
           }
        }
      });

      // 🗑️ DELETE LISTENER
      socketService.socket?.on("message_deleted", (msgId) {
        if(mounted) {
          setState(() {
             // Message remove mat karo, text replace karo WhatsApp ki tarah
             final index = _messages.indexWhere((m) => m["_id"] == msgId);
             if(index != -1) {
               _messages[index]["message"] = "🚫 This message was deleted";
               _messages[index]["deletedForEveryone"] = true;
             }
          });
        }
      });

      // ✏️ EDIT LISTENER
      socketService.socket?.on("message_edited", (data) {
         if(mounted) {
           setState(() {
             final index = _messages.indexWhere((m) => m["_id"] == data['messageId']);
             if(index != -1) {
               _messages[index]["message"] = data['newText'];
             }
           });
         }
      });

      // ⌨️ TYPING INDICATORS
      socketService.socket?.on("typing", (data) {
         if (data == _socketRoomId && mounted) setState(() => _isOtherTyping = true);
      });
      socketService.socket?.on("stopTyping", (data) {
         if (data == _socketRoomId && mounted) setState(() => _isOtherTyping = false);
      });
      
      // 3. Load History
      await _loadHistory(_socketRoomId!);
      
      // 4. Mark as Seen (immediately)
      _markAsSeen(_socketRoomId!);
    }
  }

  void _markAsSeen(String roomId) {
    socketService.socket?.emit("markAsSeen", {
      "roomId": roomId,
      "userId": widget.me,
    });
  }

  Future<void> _loadHistory(String targetRoomId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/messages/$targetRoomId"),
        headers: {"Authorization": "Bearer ${widget.jwt}"},
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List rawList = [];
        
        if (decoded['success'] == true) {
           rawList = decoded['messages'] ?? [];
        }

        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(rawList.map((m) => {
              "_id": m["_id"], 
              "message": m["deletedForEveryone"] == true ? "🚫 This message was deleted" : (m["text"] ?? m["message"] ?? ""), 
              "type": m["type"] ?? "text", 
              "senderId": m["senderId"], 
              "time": m["createdAt"] ?? DateTime.now().toString(),
              "status": m["status"] ?? "sent",
              "deletedForEveryone": m["deletedForEveryone"] ?? false
            }));
            _isLoading = false;
          });
          _scrollToBottom();
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) { 
      setState(() => _isLoading = false);
    }
  }

  void _onMessageReceived(dynamic data) {
    if (!mounted) return;
    final incomingSenderId = data["senderId"];

    if (incomingSenderId == widget.me) return; // Skip own messages loopback

    setState(() {
      _messages.add({
        "_id": data["_id"] ?? DateTime.now().toString(), 
        "message": data["message"] ?? data["text"] ?? "",
        "type": data["type"] ?? "text",
        "senderId": incomingSenderId,
        "time": DateTime.now().toString(),
        "status": "seen", // Turant seen mark kar rahe hain
        "deletedForEveryone": false
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
      _editMessageApi();
    } else {
      _sendMessage(_controller.text.trim(), "text");
    }
  }

  void _sendMessage(String content, String type) async {
    if (content.isEmpty || _socketRoomId == null) return;
    
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      _messages.add({
        "_id": tempId,
        "message": content,
        "type": type,
        "senderId": widget.me,
        "time": DateTime.now().toString(),
        "status": "sent",
        "deletedForEveryone": false
      });
    });

    // 1. Socket Emit
    socketService.sendMessage(
        roomId: _socketRoomId!, 
        message: content, 
        senderId: widget.me, 
        receiverId: widget.other,
        type: type // Added type
    );

    // 2. API Call (Save to DB)
    try {
      final res = await http.post(Uri.parse("$baseUrl/api/messages"),
        headers: {"Authorization": "Bearer ${widget.jwt}", "Content-Type": "application/json"},
        body: jsonEncode({
          "roomId": _socketRoomId, 
          "senderId": widget.me, // ✅ Added senderId
          "text": content, // Backend expects 'text'
          "type": type,
          "senderName": widget.myName ?? "Unknown", 
          "receiverName": widget.otherName 
        })
      );
      
      if(res.statusCode == 200) {
         final data = jsonDecode(res.body);
         // Update Temp ID with Real ID from DB
         final index = _messages.indexWhere((m) => m["_id"] == tempId);
         if(index != -1 && data['message'] != null) {
           setState(() {
             _messages[index]['_id'] = data['message']['_id'];
           });
         }
      }
    } catch (e) {
      print("❌ Message Save Error: $e");
    }
    
    _controller.clear();
    setState(() {}); 
    _scrollToBottom();
  }

  // 📞 CALL FEATURES
  void _openVideoCall() {
    _startCall('video');
  }

  void _openAudioCall() {
    _startCall('audio');
  }

  void _startCall(String type) {
    if (socketService.socket == null || !socketService.socket!.connected) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connecting... Please wait")));
       return;
    }

    // Call Service se Call Start karo
    CallService().startCall(context, socketService.socket, widget.other, widget.otherName, widget.me);
    
    // Navigate to Call Screen
    Navigator.push(context, MaterialPageRoute(builder: (_) => VideoCallScreen(
      targetId: widget.other, 
      name: widget.otherName, 
      isCaller: true,
      socket: socketService.socket,
      myId: widget.me, // 🔥 Important for history
    )));
  }

  void _startRecording() {
    setState(() { _isRecording = true; _recordDuration = 0; });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() { _recordDuration++; });
    });
  }

  void _stopRecording() {
    _recordTimer?.cancel();
    setState(() { _isRecording = false; });
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
        // Real app mein Image Upload karke URL bhejna chahiye, abhi ke liye base64 demo
        _sendMessage("Image Sent", "image"); 
      }
    } catch (e) { print("Image Pick Error: $e"); }
  }

  // ✏️ EDIT MESSAGE API
  Future<void> _editMessageApi() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _editingMessageId == null) return;
    
    // Optimistic Update
    setState(() {
      final index = _messages.indexWhere((m) => m["_id"] == _editingMessageId);
      if (index != -1) _messages[index]["message"] = text;
      _editingMessageId = null;
      _controller.clear();
    });

    // Socket Emit
    socketService.socket?.emit("edit_message", {
       "roomId": _socketRoomId,
       "messageId": _editingMessageId,
       "newText": text
    });

    // API Call
    try {
      await http.put(Uri.parse("$baseUrl/api/messages/$_editingMessageId"),
          headers: {"Authorization": "Bearer ${widget.jwt}", "Content-Type": "application/json"},
          body: jsonEncode({"message": text})
      );
    } catch (e) { print("Edit failed: $e"); }
  }

  // 🗑️ DELETE MESSAGE API
  Future<void> _deleteMessage(String msgId, bool forEveryone) async {
    // Local Update
    setState(() { 
      if (forEveryone) {
         final index = _messages.indexWhere((m) => m["_id"] == msgId);
         if(index != -1) {
           _messages[index]["message"] = "🚫 This message was deleted";
           _messages[index]["deletedForEveryone"] = true;
         }
      } else {
         _messages.removeWhere((m) => m["_id"] == msgId); 
      }
    });
    
    // Socket Emit (Only if for everyone)
    if (forEveryone && socketService.socket != null) {
      socketService.socket!.emit("delete_message", {
        "roomId": _socketRoomId,
        "messageId": msgId
      });
    }

    // API Call
    try {
      if (forEveryone) {
         // Soft Delete API
         await http.delete(Uri.parse("$baseUrl/api/messages/$msgId"),
             headers: {"Authorization": "Bearer ${widget.jwt}"},
         );
      }
    } catch (e) { print("Delete failed: $e"); }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent + 100, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  // 🟢 OPTIONS DIALOG
  void _showMessageOptions(Map<String, dynamic> msg, bool isMe) {
    if (!isMe) return; 
    
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text("Message Options"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (msg["type"] == "text" && msg["deletedForEveryone"] != true)
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text("Edit"),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() { _editingMessageId = msg["_id"]; _controller.text = msg["message"]; });
                },
              ),
            if (msg["deletedForEveryone"] != true)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete for Everyone"),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteMessage(msg["_id"], true);
                },
              ),
             ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.grey),
              title: const Text("Delete for Me"),
              onTap: () {
                Navigator.pop(ctx);
                _deleteMessage(msg["_id"], false);
              },
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') setState(() => _messages.clear());
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(value: 'clear', child: Text('Clear Chat')),
              ];
            },
          ),
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
                      final isMe = msg["senderId"] == widget.me;
                      
                      // Date Logic
                      bool showDate = false;
                      if (i == 0) {
                        showDate = true;
                      } else {
                        final prevMsg = _messages[i - 1];
                        final currDate = DateTime.parse(msg["time"]).toLocal();
                        final prevDate = DateTime.parse(prevMsg["time"]).toLocal();
                        if (currDate.day != prevDate.day) showDate = true;
                      }

                      return Column(
                        children: [
                          if (showDate) _buildDateChip(msg["time"]),
                          GestureDetector(
                            onLongPress: () => _showMessageOptions(msg, isMe),
                            child: _buildBubble(msg, isMe),
                          ),
                        ],
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
                  columns: 7, emojiSizeMax: 32, 
                  initCategory: emoji_picker.Category.RECENT, 
                  bgColor: const Color(0xFFF2F2F2), 
                  indicatorColor: appPrimary,
                  iconColor: Colors.grey, 
                  iconColorSelected: appPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String dateStr) {
    final date = DateTime.parse(dateStr).toLocal();
    final now = DateTime.now();
    String label = DateFormat('MMM dd, yyyy').format(date);
    if (date.year == now.year && date.month == now.month && date.day == now.day) label = "Today";
    
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isMe) {
    bool isDeleted = msg["deletedForEveryone"] == true;
    
    String timeStr = "";
    try { 
      final dt = DateTime.parse(msg["time"]).toLocal(); 
      timeStr = DateFormat('h:mm a').format(dt); 
    } catch(e) { timeStr = ""; }

    IconData statusIcon = Icons.check; 
    Color statusColor = Colors.black38; 

    if (msg["status"] == "delivered") {
      statusIcon = Icons.done_all; 
      statusColor = Colors.grey; 
    } else if (msg["status"] == "seen") {
      statusIcon = Icons.done_all; 
      statusColor = Colors.blue; 
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isMe ? bubbleMy : bubbleOther, 
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 1, offset: const Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5, right: 5, top: 2, bottom: 0), 
              child: Text(
                 msg["message"] ?? "", 
                 style: TextStyle(
                   fontSize: 16, 
                   color: isDeleted ? Colors.grey : (isMe ? textMy : textOther),
                   fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal
                 )
              )
            ),
            
            Padding(
              padding: const EdgeInsets.only(right: 2, bottom: 0, top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.black54)),
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
                      decoration: const InputDecoration(hintText: "Message", border: InputBorder.none),
                      minLines: 1, maxLines: 4,
                    )),
                    IconButton(icon: const Icon(Icons.attach_file, color: Colors.grey), onPressed: () => _pickImage(ImageSource.gallery)),
                    IconButton(icon: const Icon(Icons.camera_alt, color: Colors.grey), onPressed: () => _pickImage(ImageSource.camera)),
                  ],
                ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _controller.text.isEmpty && !_isRecording ? _startRecording : _handleSendOrUpdate,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: appPrimary,
              child: Icon(_isRecording || _controller.text.isNotEmpty ? Icons.send : Icons.mic, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}