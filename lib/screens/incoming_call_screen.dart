import 'package:flutter/material.dart';
import '../services/call_service.dart'; // Audio ringtone stop karne ke liye
import 'calling_screen.dart'; 

class IncomingCallScreen extends StatefulWidget {
  final String callerId;
  final String callerName;
  final String? callerPhoto; // Optional: Agar photo dikhani ho
  final dynamic offer;
  final String callType;
  final dynamic socket; 
  final String myId; // 🔥 REQUIRED: CallingScreen ko pass karne ke liye

  const IncomingCallScreen({
    super.key, 
    required this.callerId, 
    required this.callerName,
    this.callerPhoto,
    this.offer, 
    this.callType = 'video', 
    required this.socket,
    required this.myId, // ✅ Added this
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {

  @override
  void dispose() {
    // Safety: Agar screen kisi bhi wajah se band ho, toh ringtone band honi chahiye
    CallService().stopAudio();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isVideo = widget.callType == 'video';

    return Scaffold(
      backgroundColor: Colors.blueGrey[900], // Dark Theme like WhatsApp
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          
          // 1. Call Type Label
          Text(
            "Incoming ${isVideo ? 'Video' : 'Audio'} Call", 
            style: const TextStyle(color: Colors.white54, fontSize: 18)
          ),
          const SizedBox(height: 30),
          
          // 2. Caller Avatar (Large)
          CircleAvatar(
            radius: 70, 
            backgroundColor: Colors.grey.shade800, 
            backgroundImage: (widget.callerPhoto != null && widget.callerPhoto != "") 
                ? NetworkImage(widget.callerPhoto!) 
                : null,
            child: (widget.callerPhoto == null || widget.callerPhoto == "") 
                ? const Icon(Icons.person, size: 80, color: Colors.white) 
                : null,
          ),
          
          const SizedBox(height: 20),
          
          // 3. Caller Name
          Text(
            widget.callerName, 
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
          ),
          
          const Spacer(),
          
          // 4. Action Buttons (Decline / Accept)
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 🔴 DECLINE BUTTON
                Column(
                  children: [
                    FloatingActionButton(
                      heroTag: "reject",
                      backgroundColor: Colors.redAccent,
                      elevation: 0,
                      child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                      onPressed: () {
                        // A. Audio band karo
                        CallService().stopAudio();

                        // B. Server ko bolo 'Reject' kiya
                        if (widget.socket != null) {
                          widget.socket.emit("reject_call", {
                            "from": widget.myId,
                            "to": widget.callerId
                          });
                        }
                        
                        // C. Screen band karo
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text("Decline", style: TextStyle(color: Colors.white70)),
                  ],
                ),

                // 🟢 ACCEPT BUTTON
                Column(
                  children: [
                    FloatingActionButton(
                      heroTag: "accept",
                      backgroundColor: Colors.green,
                      elevation: 0,
                      child: Icon(isVideo ? Icons.videocam : Icons.call, color: Colors.white, size: 28),
                      onPressed: () {
                        // A. Audio band karo
                        CallService().stopAudio();

                        // B. Server ko bolo 'Answered'
                        if (widget.socket != null) {
                           widget.socket.emit("answer_call", {
                              "senderId": widget.callerId, // Call karne wala
                              "to": widget.callerId,       // Usko signal bhejo
                              "answer": "picked_up"
                           });
                        }

                        // C. Navigate to Calling Screen
                        Navigator.pushReplacement(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => CallingScreen(
                              targetId: widget.callerId, 
                              name: widget.callerName,
                              callType: widget.callType,
                              socket: widget.socket, // Socket forward karo
                              myId: widget.myId,     // ✅ REQUIRED: History save karne ke liye
                            )
                          )
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text("Accept", style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}