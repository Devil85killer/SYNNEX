import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../screens/incoming_call_screen.dart';
import '../main.dart'; // NavigatorKey ke liye import

class CallService {
  // Singleton Pattern
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _autoCutTimer;
  bool isCallActive = false;

  // 🟢 1. CALL START (Krish Side)
  void startCall(BuildContext context, dynamic socket, String targetId, String name) {
    isCallActive = true;
    
    // A. Socket Event Bhejo
    socket.emit("call_user", {
      "to": targetId,
      "callType": "video",
      "offer": "dummy_offer_for_now"
    });

    // B. Sound Bajao (Dialing...)
    _playAudio('sounds/dialing.mp3');

    // C. 30 Second Timeout
    _autoCutTimer = Timer(Duration(seconds: 30), () {
      if (isCallActive) {
        print("⏳ Call Timeout - No Answer");
        endCall(socket, targetId, reason: "missed_call");
        // Screen band karo agar khuli hai
        if (navigatorKey.currentState?.canPop() ?? false) {
          navigatorKey.currentState?.pop();
        }
      }
    });
  }

  // 🔔 2. INCOMING CALL (Rakesh Side)
  void handleIncomingCall(dynamic socket, Map data) {
    if (isCallActive) {
      socket.emit("call_ended", {"to": data['from'], "reason": "user_busy"});
      return;
    }

    isCallActive = true;
    String callerId = data['from'];
    String callerName = data['callerName'] ?? "Incoming Call";

    // A. Ringtone Bajao
    _playAudio('sounds/ringtone.mp3');

    // B. Popup Screen Show karo (Using Global Key)
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          socket: socket, 
          callerId: callerId, 
          callerName: callerName,
        ),
      ),
    );
  }

  // 🛑 3. END CALL
  void endCall(dynamic socket, String targetId, {String reason = "ended"}) {
    isCallActive = false;
    _autoCutTimer?.cancel();
    _audioPlayer.stop();

    socket.emit("end_call", {"to": targetId, "reason": reason});
  }

  // 🔊 Audio Helper
  void _playAudio(String path) async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setSource(AssetSource(path));
      await _audioPlayer.resume();
    } catch (e) {
      print("Audio Error: $e");
    }
  }
  
  void stopAudio() {
    _audioPlayer.stop();
  }
}