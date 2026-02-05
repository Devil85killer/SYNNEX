import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../screens/incoming_call_screen.dart';
import '../main.dart'; // NavigatorKey yahan se aana chahiye

class CallService {
  // Singleton Pattern
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _autoCutTimer;
  bool isCallActive = false;

  // 🔥 1. INITIALIZE (Ise Home Screen par call karna zaroori hai)
  void initialize(dynamic socket, BuildContext context) {
    print("👂 CallService Started: Listening for incoming calls...");

    // Server 'incoming_call' bhej raha hai (Server logic line 108)
    socket.on("incoming_call", (data) {
      print("🔔 Incoming Call Data: $data");
      handleIncomingCall(socket, data);
    });

    // Jab call kat jaye
    socket.on("call_ended", (data) {
      print("🔕 Call Ended");
      endCallProcess();
    });

    socket.on("call_rejected", (data) {
       print("🚫 Call Rejected");
       endCallProcess();
    });
  }

  // 🟢 2. START CALL (Updated for Server Match)
  // 'myUserId' pass karna zaroori hai kyunki server ko 'callerId' chahiye
  void startCall(BuildContext context, dynamic socket, String targetId, String name, String myUserId) {
    isCallActive = true;
    
    print("🚀 Sending Call Request to Server...");
    print("Event: start_call");
    print("Data: receiverId: $targetId, callerId: $myUserId");

    // 🔥 FIX: Keys ab Server.js (Line 95) se match kar rahi hain
    socket.emit("start_call", {
      "receiverId": targetId,  // Server expects 'receiverId'
      "callerId": myUserId,    // Server expects 'callerId'
      "callerName": name,
      "callType": "video",
      "offer": "dummy_offer_for_now" // Baad mein WebRTC offer yahan aayega
    });

    // Dialing Sound
    _playAudio('sounds/dialing.mp3');

    // 30 Second Timeout
    _autoCutTimer = Timer(Duration(seconds: 30), () {
      if (isCallActive) {
        print("⏳ Call Timeout - No Answer");
        socket.emit("end_call", {"peerId": targetId, "reason": "missed_call"});
        endCallProcess();
      }
    });
  }

  // 🔔 3. HANDLE INCOMING CALL
  void handleIncomingCall(dynamic socket, Map data) {
    if (isCallActive) {
      // Agar user pehle se busy hai
      socket.emit("call_failed", {"reason": "User is busy"});
      return;
    }

    isCallActive = true;
    String callerId = data['from']; // Server sends 'from'
    String callerName = data['callerName'] ?? "Unknown Caller";

    print("📲 Showing Incoming Screen for $callerName");

    // Ringtone
    _playAudio('sounds/ringtone.mp3');

    // Popup Screen
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            socket: socket, 
            callerId: callerId, 
            callerName: callerName,
          ),
        ),
      );
    }
  }

  // 🛑 4. END CALL PROCESS
  void endCallProcess() {
    isCallActive = false;
    _autoCutTimer?.cancel();
    stopAudio();

    // Agar screen khuli hai toh band karo
    if (navigatorKey.currentState?.canPop() ?? false) {
      navigatorKey.currentState?.pop();
    }
  }

  // 🔊 Audio Helper
  void _playAudio(String path) async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setSource(AssetSource(path));
      await _audioPlayer.resume();
    } catch (e) {
      print("⚠️ Audio Error: $e");
    }
  }
  
  void stopAudio() {
    _audioPlayer.stop();
  }
}