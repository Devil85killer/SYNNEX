import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../main.dart' as app_main; // ✅ Global Socket access

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // 🔥 CORE FIX: Apna naya socket mat banao, Main.dart wala use karo!
  IO.Socket? get socket {
    if (app_main.socket != null) {
      return app_main.socket;
    }
    return null;
  }

  // Helper check
  bool get _ready => socket != null && socket!.connected;

  /// 👤 JOIN USER (Online Status)
  void joinUser(String chatifyUserId) {
    if (socket != null) {
      // Backend ke hisaab se event name 'join' ya 'register_user' ho sakta hai
      socket!.emit("join", chatifyUserId);
      print("✅ SocketService: User Joined: $chatifyUserId");
    }
  }

  /// 🚪 JOIN ROOM
  void joinRoom(String roomId) {
    if (socket != null) {
      socket!.emit("joinRoom", roomId);
      print("✅ SocketService: Joined Room: $roomId");
    }
  }

  /// 🚪 LEAVE ROOM
  void leaveRoom(String roomId) {
    if (socket != null) {
      socket!.emit("leaveRoom", roomId);
    }
  }

  /// 👀 OPEN CHAT
  void openChat(String roomId) {
    if (socket != null) {
      socket!.emit("open_chat", {"roomId": roomId});
    }
  }

  /// 📤 SEND MESSAGE (Fixed: clientId is now Optional)
  void sendMessage({
    required String roomId,
    required String receiverId,
    required String message,
    required String senderId,
    String? clientId, // 👈 FIX: Isko optional (?) bana diya
  }) {
    if (socket == null) {
      print("❌ SocketService: Cannot send message, socket is null");
      return;
    }

    print("📤 Sending Message to $roomId");

    socket!.emit("sendMessage", {
      "roomId": roomId,
      "message": message,
      "senderId": senderId,
      "receiverId": receiverId,
      "clientId": clientId ?? "android_client", // 👈 Default value de di
    });
  }

  /// 📥 RECEIVE MESSAGE
  void onReceiveMessage(Function(dynamic data) handler) {
    socket?.off("receiveMessage"); // Duplicate listeners hatana zaroori hai
    socket?.on("receiveMessage", handler);
  }

  /// 🟢 TYPING INDICATORS
  void sendTyping(String roomId) {
    if (socket != null) socket!.emit("typing", roomId);
  }

  void sendStopTyping(String roomId) {
    if (socket != null) socket!.emit("stopTyping", roomId);
  }

  void onTyping(Function(dynamic) handler) {
    socket?.off("typing");
    socket?.on("typing", handler);
  }

  void onStopTyping(Function(dynamic) handler) {
    socket?.off("stopTyping");
    socket?.on("stopTyping", handler);
  }

  /// 🔴 DISCONNECT (Listeners safai)
  void disconnect() {
    socket?.off("receiveMessage");
    socket?.off("typing");
    socket?.off("stopTyping");
    print("🔌 SocketService: Disconnected listeners");
  }
}