import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';

class CallingScreen extends StatefulWidget {
  final String targetId; // Jisko call kar rahe hain
  final String name;     // Uska naam
  final String callType; // 'audio' or 'video'
  final dynamic socket;  // Socket Object
  final String myId;     // 🔥 REQUIRED: History save karne ke liye

  const CallingScreen({
    super.key, 
    required this.targetId, 
    required this.name,
    required this.callType,
    required this.socket,
    required this.myId,
  });

  @override
  _CallingScreenState createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  final WebRTCService _service = WebRTCService();
  bool isConnected = false;
  bool isMicOn = true;
  bool isCameraOn = true;

  @override
  void initState() {
    super.initState();
    
    // UI build hone ke baad Call start karo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.socket != null) {
        print("✅ CallingScreen: Starting Call...");
        _service.init(widget.socket); 
        _service.startCall(context, widget.targetId, widget.name, widget.callType);
      } else {
        if (mounted) Navigator.pop(context);
      }
    });

    if (widget.socket != null) {
      // ✅ 1. Call Uthne par
      widget.socket.on("call_accepted", (_) {
        if (mounted) setState(() => isConnected = true);
      });
      
      // ✅ 2. Call Katne par (Remote User ne kaata)
      widget.socket.on("call_ended", (_) {
         if (mounted) Navigator.pop(context);
      });

      // ✅ 3. Call Failed (Offline/Busy) - Naya Feature
      widget.socket.on("call_failed", (data) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Call Failed: ${data['reason']}"),
              backgroundColor: Colors.red,
            )
          );
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  void dispose() {
    // 🛡️ SECURITY FIX: Sabse pehle listeners hatao
    if (widget.socket != null) {
      widget.socket.off("call_accepted");
      widget.socket.off("call_ended");
      widget.socket.off("call_failed");
    }

    // 🔥 WebRTC Cleanup
    _service.endCall(); 
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isVideo = widget.callType == 'video';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. REMOTE VIDEO (Full Screen)
          if (isVideo && isConnected)
            Positioned.fill(
              child: RTCVideoView(
                _service.remoteRenderer, 
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
              ),
            )
          else
            // Placeholder (Jab tak connect na ho ya Audio call ho)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 80, 
                    backgroundColor: Colors.grey.shade800, 
                    child: const Icon(Icons.person, size: 80, color: Colors.white)
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.name, 
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isConnected ? "Connected" : "Calling...", 
                    style: const TextStyle(color: Colors.white70, fontSize: 18)
                  ),
                ],
              ),
            ),

          // 2. LOCAL VIDEO (Self View - PiP)
          if (isVideo)
            Positioned(
              right: 20, 
              bottom: 120,
              child: Container(
                width: 100, 
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white), 
                  color: Colors.black
                ),
                child: RTCVideoView(
                  _service.localRenderer, 
                  mirror: true, 
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
                ),
              ),
            ),

          // 3. CONTROLS
          Positioned(
            bottom: 40, 
            left: 0, 
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute Button
                FloatingActionButton(
                  heroTag: "mic_btn",
                  backgroundColor: isMicOn ? Colors.white24 : Colors.white,
                  child: Icon(isMicOn ? Icons.mic : Icons.mic_off, color: isMicOn ? Colors.white : Colors.black),
                  onPressed: () {
                    // Note: Actual Mute logic _service.toggleMic() mein hona chahiye
                    setState(() => isMicOn = !isMicOn);
                  },
                ),
                
                // 🔴 END CALL BUTTON (FIXED)
                FloatingActionButton(
                  heroTag: "end_call",
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end, color: Colors.white),
                  onPressed: () {
                    // 🔥 IMPORTANT: Server ko batao
                    if (widget.socket != null) {
                      widget.socket.emit("end_call", {
                        "callerId": widget.myId,   
                        "peerId": widget.targetId, 
                        "callType": widget.callType,
                        "duration": 0
                      });
                    }

                    // ❌ Yahan _service.endCall() mat likhna!
                    // ✅ Bas pop karo, dispose() khud cleanup karega.
                    Navigator.pop(context);
                  },
                ),
                
                // Camera Toggle
                if (isVideo)
                  FloatingActionButton(
                      heroTag: "cam_btn",
                      backgroundColor: isCameraOn ? Colors.white24 : Colors.white,
                      child: Icon(isCameraOn ? Icons.videocam : Icons.videocam_off, color: isCameraOn ? Colors.white : Colors.black),
                      onPressed: () {
                        setState(() => isCameraOn = !isCameraOn);
                        // Toggle Camera Logic here
                      },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}