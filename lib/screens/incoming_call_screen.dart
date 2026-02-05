import 'package:flutter/material.dart';
import '../services/webrtc_service.dart';
import '../services/call_service.dart'; // Audio stop karne ke liye
import 'calling_screen.dart'; 

class IncomingCallScreen extends StatelessWidget {
  final String callerId;
  final String callerName;
  final dynamic offer;
  final String callType;
  final dynamic socket; 

  const IncomingCallScreen({
    super.key, 
    required this.callerId, 
    required this.callerName,
    this.offer, // Offer optional ho sakta hai starting mein
    this.callType = 'video', // Default video
    required this.socket, 
  });

  @override
  Widget build(BuildContext context) {
    bool isVideo = callType == 'video';

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          Text(
            "Incoming ${isVideo ? 'Video' : 'Audio'} Call", 
            style: const TextStyle(color: Colors.white54, fontSize: 18)
          ),
          const SizedBox(height: 30),
          
          // Caller Avatar
          const CircleAvatar(
            radius: 70, 
            backgroundColor: Colors.grey, 
            child: Icon(Icons.person, size: 70, color: Colors.white)
          ),
          
          const SizedBox(height: 20),
          Text(
            callerName, 
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
          ),
          
          const Spacer(),
          
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 🔴 DECLINE BUTTON
              Column(
                children: [
                  FloatingActionButton(
                    heroTag: "reject",
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.call_end, color: Colors.white),
                    onPressed: () {
                      // 1. Audio band karo
                      CallService().stopAudio();

                      // 2. Server ko batao ki reject kiya
                      if (socket != null) {
                        socket.emit("reject_call", {"to": callerId});
                      }
                      
                      // 3. Screen band karo
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text("Decline", style: TextStyle(color: Colors.white)),
                ],
              ),

              // 🟢 ACCEPT BUTTON
              Column(
                children: [
                  FloatingActionButton(
                    heroTag: "accept",
                    backgroundColor: Colors.green,
                    child: Icon(isVideo ? Icons.videocam : Icons.call, color: Colors.white),
                    onPressed: () {
                      // 1. Audio band karo
                      CallService().stopAudio();

                      // 2. WebRTC Answer signal bhejo (Future Implementation)
                      // WebRTCService().acceptCall(callerId, offer, callType);
                      
                      // 3. Server ko batao ki accept kiya
                      socket.emit("answer_call", {
                         "senderId": callerId, // Jisne call ki thi
                         "to": callerId,      // Usko wapas batao
                         "answer": "dummy_answer" // WebRTC baad mein
                      });

                      // 4. Calling Screen par jao
                      Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(
                          builder: (_) => CallingScreen(
                            targetId: callerId, 
                            name: callerName,
                            callType: callType,
                            socket: socket, // ✅ Passing Socket Forward
                          )
                        )
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text("Accept", style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}