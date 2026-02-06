import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../main.dart' as app_main; 

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? get socket => app_main.socket;

  // 👤 REGISTER USER (Backend event: 'setup')
  // 🔥 FIX: Maine 'register_user' ko 'setup' kar diya hai taaki Backend sun sake
  void registerUser(String userId) {
    if (socket != null) {
      
      // 1. Agar socket pehle se connected hai, toh abhi register karo
      if (socket!.connected) {
        socket!.emit("setup", userId); 
        print("✅ SocketService: User Registered (setup) -> $userId");
      }

      // 2. Agar socket disconnect hoke wapas connect ho, toh auto-register karo
      socket!.on('connect', (_) {
        socket!.emit("setup", userId);
        print("✅ SocketService: User Registered after reconnection -> $userId");
      });
    } else {
      print("⚠️ SocketService: Socket is null");
    }
  }

  // 🚪 JOIN ROOM (Backend event: 'join room')
  // Note: Backend 'join-room' ya 'join room' expect kar sakta hai, standard 'join room' hai
  void joinRoom(String roomId) {
    if (socket != null && socket!.connected) {
      socket!.emit("join room", roomId); // Agar backend me 'join-room' hai to wahi rehne dena
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
    if (socket != null && socket!.connected) {
      socket!.emit("new message", { // Backend aksar 'new message' sunta hai, check kar lena
        "roomId": roomId,
        "message": message,
        "senderId": senderId,
        "receiverId": receiverId,
        "type": type,
      });
      print("📤 Message Sent to $roomId");
    }
  }

  // 🔵 MARK AS SEEN
  void markAsSeen(String roomId, String userId) {
    if (socket != null && socket!.connected) {
      socket!.emit("markAsSeen", {
        "roomId": roomId,
        "userId": userId,
      });
    }
  }

  // 🗑️ DELETE FOR EVERYONE
  void deleteMessage(String roomId, String messageId) {
    if (socket != null && socket!.connected) {
      socket!.emit("delete_message", {
        "roomId": roomId,
        "messageId": messageId,
      });
    }
  }

  // ✏️ EDIT MESSAGE
  void editMessage(String roomId, String messageId, String newText) {
    if (socket != null && socket!.connected) {
      socket!.emit("edit_message", {
        "roomId": roomId,
        "messageId": messageId,
        "newText": newText,
      });
    }
  }

  // ==========================================
  // 📥 LISTENERS
  // ==========================================

  void onReceiveMessage(Function(dynamic data) handler) {
    socket?.off("message received"); // Backend event name check karna ('message received' vs 'receiveMessage')
    socket?.on("message received", handler);
  }

  void onMessagesSeen(Function(dynamic data) handler) {
    socket?.off("messages_seen");
    socket?.on("messages_seen", handler);
  }

  void onMessageDeleted(Function(dynamic messageId) handler) {
    socket?.off("message_deleted");
    socket?.on("message_deleted", handler);
  }

  void onMessageEdited(Function(dynamic data) handler) {
    socket?.off("message_edited");
    socket?.on("message_edited", handler);
  }

  void sendTyping(String roomId) => socket?.emit("typing", roomId);
  void sendStopTyping(String roomId) => socket?.emit("stop typing", roomId);

  void onTyping(Function(dynamic) handler) {
    socket?.off("typing");
    socket?.on("typing", handler);
  }

  void onStopTyping(Function(dynamic) handler) {
    socket?.off("stop typing");
    socket?.on("stop typing", handler);
  }

  void disconnect() {
    socket?.off("message received");
    socket?.off("messages_seen");
    socket?.off("message_deleted");
    socket?.off("message_edited");
    socket?.off("typing");
    socket?.off("stop typing");
    print("🔌 SocketService: Listeners Cleared");
  }
}