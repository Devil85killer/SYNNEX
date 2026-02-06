import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../main.dart' as app_main; 

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? get socket => app_main.socket;

  // 👤 REGISTER USER (Backend event: 'register_user')
  void registerUser(String userId) {
    if (socket != null) {
      socket!.emit("register_user", userId);
      print("✅ SocketService: User Registered: $userId");
    }
  }

  // 🚪 JOIN ROOM (Backend event: 'join-room')
  void joinRoom(String roomId) {
    if (socket != null) {
      socket!.emit("join-room", roomId);
      print("✅ SocketService: Joined Room: $roomId");
    }
  }

  // 📤 SEND MESSAGE
  void sendMessage({
    required String roomId,
    required String receiverId,
    required String message,
    required String senderId,
    String type = 'text', 
  }) {
    if (socket != null) {
      socket!.emit("sendMessage", {
        "roomId": roomId,
        "message": message,
        "senderId": senderId,
        "receiverId": receiverId,
        "type": type,
      });
      print("📤 Message Sent to $roomId");
    }
  }

  // 🔵 MARK AS SEEN (Blue Ticks Trigger)
  void markAsSeen(String roomId, String userId) {
    if (socket != null) {
      socket!.emit("markAsSeen", {
        "roomId": roomId,
        "userId": userId, // Wo user jisne chat kholi hai
      });
    }
  }

  // 🗑️ DELETE FOR EVERYONE
  void deleteMessage(String roomId, String messageId) {
    if (socket != null) {
      socket!.emit("delete_message", {
        "roomId": roomId,
        "messageId": messageId,
      });
    }
  }

  // ✏️ EDIT MESSAGE
  void editMessage(String roomId, String messageId, String newText) {
    if (socket != null) {
      socket!.emit("edit_message", {
        "roomId": roomId,
        "messageId": messageId,
        "newText": newText,
      });
    }
  }

  // ==========================================
  // 📥 LISTENERS (Saamne wale ka data pakadne ke liye)
  // ==========================================

  // 📩 Naya Message Aane Par
  void onReceiveMessage(Function(dynamic data) handler) {
    socket?.off("receiveMessage");
    socket?.on("receiveMessage", handler);
  }

  // 🔵 Blue Ticks Aane Par
  void onMessagesSeen(Function(dynamic data) handler) {
    socket?.off("messages_seen");
    socket?.on("messages_seen", handler);
  }

  // 🗑️ Message Delete Hone Par
  void onMessageDeleted(Function(dynamic messageId) handler) {
    socket?.off("message_deleted");
    socket?.on("message_deleted", handler);
  }

  // ✏️ Message Edit Hone Par
  void onMessageEdited(Function(dynamic data) handler) {
    socket?.off("message_edited");
    socket?.on("message_edited", handler);
  }

  // 🟢 Typing Indicators
  void sendTyping(String roomId) => socket?.emit("typing", roomId);
  void sendStopTyping(String roomId) => socket?.emit("stopTyping", roomId);

  void onTyping(Function(dynamic) handler) {
    socket?.off("typing");
    socket?.on("typing", handler);
  }

  void onStopTyping(Function(dynamic) handler) {
    socket?.off("stopTyping");
    socket?.on("stopTyping", handler);
  }

  void disconnect() {
    socket?.off("receiveMessage");
    socket?.off("messages_seen");
    socket?.off("message_deleted");
    socket?.off("message_edited");
    print("🔌 SocketService: Listeners Cleared");
  }
}