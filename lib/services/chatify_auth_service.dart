import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? socket;
  bool _isConnected = false;

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  IO.Socket? get getSocket => socket;
  bool get isConnected => _isConnected;

  // ✅ Initialize Socket
  void initSocket(String token) {
    if (_isConnected) {
      debugPrint("⚠️ Socket already connected.");
      return;
    }

    // Replace with your Render URL
    const String serverUrl = "https://synnex.onrender.com"; 

    debugPrint("🔌 Connecting to Socket...");

    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token}, // Auth Token bhejna zaroori hai
    });

    socket!.connect();

    socket!.onConnect((_) {
      _isConnected = true;
      debugPrint("✅ ✅ SOCKET CONNECTED SUCCESSFULLY!");
      debugPrint("🔗 Connection ID: ${socket!.id}");
    });

    socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint("❌ Socket Disconnected");
    });

    socket!.onError((data) => debugPrint("❌ Socket Error: $data"));
  }

  // ✅ Join Room (Chat start karne ke liye)
  void joinRoom(String roomId) {
    if (socket != null && _isConnected) {
      socket!.emit('join-room', roomId);
      debugPrint("------------------------------------------------");
      debugPrint("🏠 JOINED ROOM: $roomId");
      debugPrint("------------------------------------------------");
    }
  }

  // 🔥 MAIN PART: SEND MESSAGE WITH LOGS 🔥
  void sendMessage({
    required String roomId,
    required String message,
    required String senderId,
    required String receiverId,
  }) {
    if (socket != null && _isConnected) {
      
      // 🧐 TERMINAL PROOF: "Kisne Kisko Msg Diya"
      debugPrint("\n📨 📨 MESSAGE SENT! 📨 📨");
      debugPrint("------------------------------------------------");
      debugPrint("🏠 Room ID     : $roomId");
      debugPrint("📤 From (Me)   : $senderId");
      debugPrint("📥 To (Other)  : $receiverId");
      debugPrint("💬 Content     : \"$message\"");
      debugPrint("📂 Stored In   : MongoDB 'messages' collection");
      debugPrint("------------------------------------------------\n");

      // Asli data bhejo
      socket!.emit('sendMessage', {
        'roomId': roomId,
        'message': message,
        'senderId': senderId,
        'receiverId': receiverId,
        'type': 'text', // text/image/video
      });

    } else {
      debugPrint("❌ ERROR: Socket not connected. Message nahi gaya.");
    }
  }

  // ✅ Listen for incoming messages
  void onReceiveMessage(Function(dynamic) callback) {
    socket?.on('receiveMessage', (data) {
      debugPrint("\n📩 NEW MESSAGE RECEIVED!");
      debugPrint("👤 Sender: ${data['senderId']}");
      debugPrint("💬 Msg: ${data['message']}");
      callback(data);
    });
  }

  // ✅ Disconnect
  void disconnect() {
    socket?.disconnect();
    _isConnected = false;
  }
}