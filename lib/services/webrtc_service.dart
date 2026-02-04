import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:audioplayers/audioplayers.dart';
import '../main.dart' as app_main; 
import '../screens/calling_screen.dart';
import '../screens/incoming_call_screen.dart';

class WebRTCService {
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

  dynamic get socket {
    if (_localSocket != null) return _localSocket;
    if (app_main.socket != null) return app_main.socket;
    return null;
  }

  final Map<String, dynamic> _config = {
    'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}],
    'sdpSemantics': 'unified-plan'
  };

  void init(dynamic socketInstance) {
    _localSocket = socketInstance;
    localRenderer.initialize();
    remoteRenderer.initialize();

    if (socket == null) return;

    socket?.on("call_accepted", (data) async {
      _stopAudio();
      _autoCutTimer?.cancel(); 
      
      if (_peerConnection != null && 
          _peerConnection!.signalingState != RTCSignalingState.RTCSignalingStateStable) {
        var answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
        await _peerConnection?.setRemoteDescription(answer);
      }
    });

    socket?.on("ice_candidate", (data) async {
      // 🔥 FIX: 'remoteDescription' getter error resolved
      // SignalingState check karke pata chalta hai ki description set ho chuki hai ya nahi
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

    socket?.on("call_ended", (data) {
      endCall(isRemote: true);
    });

    socket?.on("call_error", (data) {
      print("❌ WebRTC Call Error: ${data['reason']}");
      endCall();
    });
  }

  Future<void> startCall(BuildContext context, String targetId, String name, String callType) async {
    if (socket == null || isCallActive) return;

    isCallActive = true;
    _playAudio('sounds/dialing.mp3');

    bool mediaSuccess = await _openUserMedia(callType == 'video'); 
    if (!mediaSuccess) {
      endCall();
      return;
    }

    await _createPeerConnection(targetId);

    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    socket?.emit("call_user", {
      "to": targetId,
      "offer": {"sdp": offer.sdp, "type": offer.type},
      "callType": callType 
    });

    _autoCutTimer = Timer(const Duration(seconds: 45), () {
      if (isCallActive) {
        socket?.emit("end_call", {"to": targetId, "reason": "missed_call"});
        endCall();
      }
    });
  }

  Future<void> handleIncomingCall(Map data) async {
    if (isCallActive) {
      socket?.emit("call_error", {"to": data['from'], "reason": "User is Busy"});
      return;
    }
    
    isCallActive = true;
    _playAudio('sounds/ringtone.mp3');

    if (app_main.navigatorKey.currentState != null) {
      app_main.navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            callerId: data['from'], 
            callerName: data['callerName'] ?? "Unknown", 
            offer: data['offer'],
            callType: data['callType'] ?? 'video',
            socket: socket, 
          ),
        ),
      );
    }
  }

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
    } catch (e) { print("Cleanup error: $e"); }

    if (app_main.navigatorKey.currentState?.canPop() ?? false) {
      app_main.navigatorKey.currentState?.pop();
    }
  }

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