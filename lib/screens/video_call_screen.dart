import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String targetId; // Jisko call kar rahe ho
  final String name;     // Uska naam
  final bool isCaller;   // Kya maine call kiya hai?
  final dynamic socket;  // 🔥 REQUIRED: Socket connection
  final String myId;     // 🔥 REQUIRED: History save karne ke liye

  const VideoCallScreen({
    super.key, 
    required this.targetId, 
    required this.name,
    required this.isCaller,
    required this.socket,
    required this.myId,
  });

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final WebRTCService _service = WebRTCService();
  bool isConnected = false;
  bool isMicOn = true;

  @override
  void initState() {
    super.initState();
    
    // UI render hone ke baad call process start karo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.socket != null) {
        print("🎥 VideoCallScreen: Starting...");
        _service.init(widget.socket); 
        
        // Agar main caller hoon toh offer bhejo, nahi toh answer ka wait karo
        if (widget.isCaller) {
           _service.startCall(context, widget.targetId, widget.name, 'video');
        }
      } else {
        Navigator.pop(context); // Socket nahi hai toh wapas jao
      }
    });

    if (widget.socket != null) {
      // ✅ Call Uthne par
      widget.socket.on("call_accepted", (_) {
        if(mounted) setState(() => isConnected = true);
      });
      
      // ✅ Call Katne par
      widget.socket.on("call_ended", (_) {
         if(mounted) Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    _service.endCall(); // Memory leak rokne ke liye zaroori hai
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. REMOTE VIDEO (Full Screen)
          Positioned.fill(
            child: isConnected 
              ? RTCVideoView(
                  _service.remoteRenderer, 
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       const CircleAvatar(
                         radius: 60, 
                         backgroundColor: Colors.grey, 
                         child: Icon(Icons.person, size: 60, color: Colors.white)
                       ),
                       const SizedBox(height: 20),
                       Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 10),
                       const Text("Connecting...", style: TextStyle(color: Colors.white54, fontSize: 16)),
                       const SizedBox(height: 20),
                       const CircularProgressIndicator(color: Colors.white),
                    ],
                  ),
                ),
          ),
          
          // 2. LOCAL VIDEO (Pip - Picture in Picture)
          Positioned(
            right: 20,
            bottom: 120,
            child: Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(10),
                color: Colors.black
              ),
              child: RTCVideoView(
                _service.localRenderer,
                mirror: true, // Selfie camera mirror hona chahiye
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),

          // 3. CONTROLS (End Call, Mute)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute Button
                FloatingActionButton(
                  heroTag: "mute",
                  backgroundColor: isMicOn ? Colors.white24 : Colors.white,
                  child: Icon(isMicOn ? Icons.mic : Icons.mic_off, color: isMicOn ? Colors.white : Colors.black),
                  onPressed: () {
                    setState(() => isMicOn = !isMicOn);
                    // Mute logic _service mein add kar lena
                  },
                ),

                // 🔴 END CALL BUTTON
                FloatingActionButton(
                  heroTag: "end",
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end, color: Colors.white),
                  onPressed: () {
                    // 🔥 BACKEND FIX: History save karne ke liye data bhejo
                    if (widget.socket != null) {
                      widget.socket.emit("end_call", {
                        "callerId": widget.myId,    // ✅ Call History ke liye
                        "peerId": widget.targetId,  // ✅ Room close ke liye
                        "callType": 'video',
                        "duration": 0
                      });
                    }
                    _service.endCall();
                    Navigator.pop(context);
                  },
                ),
                
                // Camera Switch (Optional)
                FloatingActionButton(
                  heroTag: "switch",
                  backgroundColor: Colors.white24,
                  child: const Icon(Icons.switch_camera, color: Colors.white),
                  onPressed: () {
                    // _service.switchCamera(); // Service mein implement karna padega
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