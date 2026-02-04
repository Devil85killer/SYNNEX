import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../main.dart' as app_main; // ✅ ACCESS GLOBAL SOCKET

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // 🔥 CORE FIX: Apna naya socket mat banao, Main.dart wala use karo!
  IO.Socket? get socket {
    if (app_main.socket != null && app_main.socket!.connected) {
      return app_main.socket;
    }
    return null;
  }

  // Helper check
  bool get _ready => socket != null;

  // ⚠️ Note: connect() function hata diya hai kyunki main.dart connect karega.

  /// 👤 JOIN USER (Online Status)
  void joinUser(String chatifyUserId) {
    if (_ready) {
      socket!.emit("join", chatifyUserId);
      print("✅ SocketService: Joined as User: $chatifyUserId");
    }
  }

  /// 🚪 JOIN ROOM
  void joinRoom(String roomId) {
    if (_ready) {
      socket!.emit("joinRoom", roomId); 
      print("✅ SocketService: Joined Room: $roomId");
    } else {
      print("⚠️ SocketService: Cannot join room, socket disconnected");
    }
  }

  /// 🚪 LEAVE ROOM
  void leaveRoom(String roomId) {
    if (_ready) {
      socket!.emit("leaveRoom", roomId);
    }
  }

  /// 👀 OPEN CHAT
  void openChat(String roomId) {
    if (_ready) {
      socket!.emit("open_chat", {"roomId": roomId});
    }
  }

  /// 📤 SEND MESSAGE
  void sendMessage({
    required String roomId,
    required String receiverId,
    required String message,
    required String clientId,
    required String senderId, 
  }) {
    if (!_ready) {
      print("❌ SocketService: Cannot send message, socket disconnected");
      return;
    }

    socket!.emit("sendMessage", {
      "roomId": roomId,
      "message": message,
      "senderId": senderId, 
      "receiverId": receiverId,
      "clientId": clientId,
    });
  }

  /// 📥 RECEIVE MESSAGE
  void onReceiveMessage(Function(dynamic data) handler) {
    // Duplicate listeners avoid karne ke liye pehle off karo
    socket?.off("receiveMessage");
    socket?.on("receiveMessage", handler);
  }

  /// 🟢 TYPING INDICATORS
  void sendTyping(String roomId) {
    if (_ready) socket!.emit("typing", roomId);
  }

  void sendStopTyping(String roomId) {
    if (_ready) socket!.emit("stopTyping", roomId);
  }

  void onTyping(Function(dynamic) handler) {
    socket?.off("typing");
    socket?.on("typing", handler);
  }

  void onStopTyping(Function(dynamic) handler) {
    socket?.off("stopTyping");
    socket?.on("stopTyping", handler);
  }

  /// 🔴 DISCONNECT (Sirf Listeners hatao, connection mat kato)
  void disconnect() {
    // Hum actual socket disconnect nahi karenge kyunki wo calls ke liye bhi chahiye.
    // Bas listeners clean kar denge.
    socket?.off("receiveMessage");
    socket?.off("typing");
    socket?.off("stopTyping");
  }
}