import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';

class VideoCallScreen extends StatefulWidget {
  final bool isCaller;
  const VideoCallScreen({super.key, required this.isCaller});

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final WebRTCService _service = WebRTCService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Remote Video (Full Screen)
          Positioned.fill(
            child: RTCVideoView(
              _service.remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
          
          // 2. Local Video (Small Overlay)
          Positioned(
            right: 20,
            bottom: 100,
            child: Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(border: Border.all(color: Colors.white)),
              child: RTCVideoView(
                _service.localRenderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),

          // 3. End Call Button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: Colors.red,
                child: const Icon(Icons.call_end),
                onPressed: () {
                  // Socket se event bhejo ki maine kaat diya
                  _service.socket.emit("end_call", {"to": "remote_id_handle_later"}); 
                  // Note: Clean implementation ke liye targetId save rakhna padega service mein
                  _service.endCall();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}