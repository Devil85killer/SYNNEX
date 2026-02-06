const Call = require('../models/Call'); // Call Model Zaroori hai History ke liye

module.exports = (io, socket, onlineUsers, callState, activeCallPeer) => {
  
  // 1. START CALL (Notification & Vibration Trigger)
  socket.on("start_call", async (data) => {
    console.log(`📞 Call Request: ${data.callerId} -> ${data.receiverId}`);

    const receiverSocketId = onlineUsers.get(data.receiverId);

    // Agar User OFFLINE hai -> Missed Call save karo turant
    if (!receiverSocketId) {
      console.log(`⚠️ User ${data.receiverId} is OFFLINE`);
      socket.emit("call_failed", { reason: "User is offline" });

      // Save Missed Call in DB
      try {
        await new Call({
            callerId: data.callerId,
            receiverId: data.receiverId,
            type: data.callType || 'audio',
            status: 'missed',
            startedAt: new Date(),
            endedAt: new Date()
        }).save();
      } catch(e) { console.log("Save Call Error:", e); }
      
      return;
    }

    // Agar User BUSY hai -> Busy log karo
    if (callState.has(data.receiverId)) {
      console.log(`⚠️ User ${data.receiverId} is BUSY`);
      socket.emit("call_failed", { reason: "User is busy" });
      return;
    }

    // Send Incoming Call Signal (Ye App/Web par Popup layega)
    io.to(receiverSocketId).emit("incoming_call", {
      from: data.callerId,
      callerName: data.callerName || "Unknown",
      callType: data.callType || 'audio', // audio/video
      offer: data.offer
    });
  });

  // 2. ANSWER CALL
  socket.on("answer_call", (data) => {
    console.log(`✅ Call Accepted by ${data.senderId}`);
    const callerSocketId = onlineUsers.get(data.to);

    if (callerSocketId) {
      // Mark users as busy
      callState.set(data.senderId, true);
      callState.set(data.to, true);

      // Track peers for disconnect handling
      activeCallPeer.set(socket.id, callerSocketId);
      activeCallPeer.set(callerSocketId, socket.id);

      io.to(callerSocketId).emit("call_accepted", {
        answer: data.answer,
      });
    } else {
       socket.emit("call_ended"); 
    }
  });

  // 3. ICE CANDIDATES
  socket.on("ice_candidate", (data) => {
    const targetSocketId = onlineUsers.get(data.to);
    if (targetSocketId) {
      io.to(targetSocketId).emit("ice_candidate", {
        candidate: data.candidate,
      });
    }
  });

  // 4. END CALL (Save History)
  socket.on("end_call", async (data) => {
    console.log(`🛑 Call Ended`);
    
    // Notify other user
    if (data.peerId) {
        const peerSocketId = onlineUsers.get(data.peerId);
        if (peerSocketId) io.to(peerSocketId).emit("call_ended");
        // Free up busy state
        callState.delete(data.peerId);
    }
    
    // Free up my busy state
    if(data.callerId) callState.delete(data.callerId);

    // 🔥 SAVE CALL HISTORY IN DB
    if (data.callerId && data.peerId) {
        try {
            await new Call({
                callerId: data.callerId, // Jisne call kiya
                receiverId: data.peerId, // Jisko call kiya
                type: data.callType || 'audio',
                status: 'ended', // Successfully talked
                duration: data.duration || 0, // Frontend se duration bhejna padega
                startedAt: new Date(), // Approx logic
                endedAt: new Date()
            }).save();
            console.log("💾 Call History Saved");
        } catch (e) { console.log("History Error:", e); }
    }
  });

  // 5. REJECT CALL (Save History)
  socket.on("reject_call", async (data) => {
     console.log(`🚫 Call Rejected`);
     const callerSocketId = onlineUsers.get(data.to);
     if (callerSocketId) io.to(callerSocketId).emit("call_rejected");

     // Save Rejected Call
     try {
        await new Call({
            callerId: data.to, // Original Caller
            receiverId: data.from, // Jisne reject kiya
            type: 'audio', // Default or pass from frontend
            status: 'rejected',
            duration: 0,
            startedAt: new Date(),
            endedAt: new Date()
        }).save();
     } catch (e) { console.log("History Error:", e); }
  });

  // 6. DISCONNECT
  socket.on("disconnect", () => {
    const peerSocketId = activeCallPeer.get(socket.id);
    if (peerSocketId) {
      io.to(peerSocketId).emit("call_ended");
      activeCallPeer.delete(peerSocketId);
      activeCallPeer.delete(socket.id);
    }
    
    // Remove user from online map
    for (let [userId, socketId] of onlineUsers.entries()) {
        if (socketId === socket.id) {
            onlineUsers.delete(userId);
            callState.delete(userId);
            console.log(`❌ User Offline: ${userId}`);
            break;
        }
    }
  });
};