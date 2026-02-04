import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';

class CallingScreen extends StatefulWidget {
  final String targetId;
  final String name;
  final String callType; // 'audio' or 'video'
  final dynamic socket;  // 🔥 Socket is Required

  const CallingScreen({
    super.key, 
    required this.targetId, 
    required this.name,
    required this.callType,
    required this.socket, 
  });

  @override
  _CallingScreenState createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  final WebRTCService _service = WebRTCService();
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.socket != null) {
        print("✅ CallingScreen: Starting Call with Socket");
        _service.init(widget.socket); 
        _service.startCall(context, widget.targetId, widget.name, widget.callType);
      } else {
        Navigator.pop(context);
      }
    });

    if (widget.socket != null) {
      widget.socket.on("call_accepted", (_) {
        if(mounted) setState(() => isConnected = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isVideo = widget.callType == 'video';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Remote View
          if (isVideo && isConnected)
            Positioned.fill(
              child: RTCVideoView(_service.remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 80, backgroundColor: Colors.grey.shade800, child: const Icon(Icons.person, size: 80, color: Colors.white)),
                  const SizedBox(height: 20),
                  Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(isConnected ? "Connected" : "Calling...", style: const TextStyle(color: Colors.white70, fontSize: 18)),
                ],
              ),
            ),

          // 2. Local View
          if (isVideo)
            Positioned(
              right: 20, bottom: 120,
              child: Container(
                width: 100, height: 150,
                decoration: BoxDecoration(border: Border.all(color: Colors.white), color: Colors.black),
                child: RTCVideoView(_service.localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
              ),
            ),

          // 3. Controls
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: "mic_off",
                  backgroundColor: Colors.white24,
                  child: const Icon(Icons.mic_off, color: Colors.white),
                  onPressed: () {},
                ),
                FloatingActionButton(
                  heroTag: "end_call",
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end, color: Colors.white),
                  onPressed: () {
                    if (widget.socket != null) {
                      widget.socket.emit("end_call", {"to": widget.targetId, "reason": "canceled"});
                    }
                    _service.endCall();
                    Navigator.pop(context);
                  },
                ),
                if (isVideo)
                  FloatingActionButton(
                     heroTag: "video_off",
                     backgroundColor: Colors.white24,
                     child: const Icon(Icons.videocam_off, color: Colors.white),
                     onPressed: () {},
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}