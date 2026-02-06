import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../main.dart' as app_main; 
import '../screens/calling_screen.dart';
import '../screens/incoming_call_screen.dart';

class WebRTCService {
  // Singleton Logic
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _autoCutTimer;
  bool isCallActive = false;
  dynamic _localSocket;

  // Socket Getter: Local ya Global check karta hai
  dynamic get socket {
    if (_localSocket != null) return _localSocket;
    if (app_main.socket != null) return app_main.socket;
    return null;
  }

  final Map<String, dynamic> _config = {
    'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}],
    'sdpSemantics': 'unified-plan'
  };

  // ==========================================
  // 1. INIT: Listeners Set Karna
  // ==========================================
  void init(dynamic socketInstance) {
    _localSocket = socketInstance;
    localRenderer.initialize();
    remoteRenderer.initialize();

    if (socket == null) return;

    // ✅ Signal 1: Call Accepted
    socket?.on("call_accepted", (data) async {
      _stopAudio();
      _autoCutTimer?.cancel(); 
      
      if (_peerConnection != null && 
          _peerConnection!.signalingState != RTCSignalingState.RTCSignalingStateStable) {
        var answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
        await _peerConnection?.setRemoteDescription(answer);
      }
    });

    // ✅ Signal 2: ICE Candidate
    socket?.on("ice_candidate", (data) async {
      if (_peerConnection != null && 
          _peerConnection!.signalingState != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        var candidate = RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        );
        await _peerConnection?.addCandidate(candidate);
      }
    });

    // ✅ Signal 3: Call Ended by Remote User
    socket?.on("call_ended", (data) {
      // Sirf tab handle karo jab saamne wale ne kaata ho
      endCall(isRemote: true);
    });

    // ✅ Signal 4: Error (Busy/Offline)
    socket?.on("call_error", (data) {
      print("❌ WebRTC Call Error: ${data['reason']}");
      endCall(isRemote: true); // Error hai toh band kar do
    });
  }

  // ==========================================
  // 2. CALL START KARNA (Dialing) - 🔥 FIXED
  // ==========================================
  Future<void> startCall(BuildContext context, String targetId, String receiverName, String callType) async {
    if (socket == null || isCallActive) return;

    isCallActive = true;
    _playAudio('sounds/dialing.mp3');

    // ✅ 1. Get My ID & Name from Storage (Backend needs this)
    final prefs = await SharedPreferences.getInstance();
    final String myMongoId = prefs.getString('uid') ?? ""; 
    final String myName = prefs.getString('name') ?? "Unknown"; 

    bool mediaSuccess = await _openUserMedia(callType == 'video'); 
    if (!mediaSuccess) {
      endCall();
      return;
    }

    await _createPeerConnection(targetId);

    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    print("🚀 Sending Call Request: $myMongoId -> $targetId ($callType)");

    // 🔥 FIX: Event Name changed from 'call_user' to 'start_call' matches Backend
    socket?.emit("start_call", {
      "callerId": myMongoId,       // Backend: data.callerId
      "receiverId": targetId,      // Backend: data.receiverId
      "callerName": myName,        // Receiver ko dikhega
      "callType": callType,
      "offer": {"sdp": offer.sdp, "type": offer.type}
    });

    // 45 sec baad auto cut agar uthaya nahi
    _autoCutTimer = Timer(const Duration(seconds: 45), () {
      if (isCallActive) {
        // 🔥 FIX: Backend ke 'end_call' format se match kiya
        socket?.emit("end_call", {
          "callerId": myMongoId, 
          "peerId": targetId, 
          "reason": "missed_call"
        });
        endCall(isRemote: true); // Timeout ko remote end ki tarah treat karo
      }
    });
  }

  // ==========================================
  // 3. INCOMING CALL HANDLE KARNA
  // ==========================================
  Future<void> handleIncomingCall(Map data) async {
    if (isCallActive) {
      socket?.emit("call_error", {"to": data['from'], "reason": "User is Busy"});
      return;
    }
    
    isCallActive = true;
    _playAudio('sounds/ringtone.mp3');

    // ✅ MongoDB ID nikalna zaroori hai Screen pass karne ke liye
    final prefs = await SharedPreferences.getInstance();
    final String myMongoId = prefs.getString('uid') ?? ""; 

    if (app_main.navigatorKey.currentState != null) {
      app_main.navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            callerId: data['from'], 
            callerName: data['callerName'] ?? "User", 
            offer: data['offer'],
            callType: data['callType'] ?? 'video',
            socket: socket,
            myId: myMongoId, // 🔥 Passing ID Fixed
          ),
        ),
      );
    }
  }

  // ==========================================
  // 4. CALL ACCEPT KARNA
  // ==========================================
  Future<void> acceptCall(String callerId, dynamic remoteOffer, String callType) async {
    _stopAudio();
    _autoCutTimer?.cancel();

    bool mediaSuccess = await _openUserMedia(callType == 'video');
    if (!mediaSuccess) {
      endCall();
      return;
    }

    await _createPeerConnection(callerId);

    await _peerConnection?.setRemoteDescription(
      RTCSessionDescription(remoteOffer['sdp'], remoteOffer['type'])
    );

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    socket?.emit("call_accepted", {
      "to": callerId,
      "answer": {"sdp": answer.sdp, "type": answer.type}
    });
  }

  // ==========================================
  // 5. END CALL (CRITICAL FIX APPLIED HERE) 🛠️
  // ==========================================
  void endCall({bool isRemote = false}) {
    isCallActive = false;
    _autoCutTimer?.cancel();
    _stopAudio();

    try {
      _localStream?.getTracks().forEach((track) => track.stop());
      _localStream?.dispose();
      _localStream = null;
      
      _peerConnection?.close();
      _peerConnection = null;
      
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    } catch (e) { 
      print("Cleanup error: $e"); 
    }

    // 🔥 FIX: Sirf tab pop karo jab call Remote (Server/Other User) ne kaati ho.
    // Agar User ne khud Red button dabaya, toh UI already pop ho chuka hai.
    if (isRemote) {
      if (app_main.navigatorKey.currentState?.canPop() ?? false) {
        app_main.navigatorKey.currentState?.pop();
      }
    }
  }

  // ==========================================
  // 6. HELPER FUNCTIONS
  // ==========================================
  Future<bool> _openUserMedia(bool isVideo) async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': isVideo ? {'facingMode': 'user'} : false
      });
      localRenderer.srcObject = _localStream;
      return true;
    } catch(e) { 
      print("🚫 Camera/Mic Access Denied: $e"); 
      return false;
    }
  }

  Future<void> _createPeerConnection(String targetId) async {
    _peerConnection = await createPeerConnection(_config);
    
    _peerConnection!.onIceCandidate = (candidate) {
      if (socket != null && isCallActive) {
        socket?.emit("ice_candidate", {
          "to": targetId,
          "candidate": {
            "sdpMid": candidate.sdpMid,
            "sdpMLineIndex": candidate.sdpMLineIndex,
            "candidate": candidate.candidate,
          }
        });
      }
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    _localStream?.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
  }

  void _playAudio(String path) async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(path));
    } catch(e) { print("🔊 Audio Error: $e"); }
  }

  void _stopAudio() async {
    try { await _audioPlayer.stop(); } catch(e) {}
  }
}