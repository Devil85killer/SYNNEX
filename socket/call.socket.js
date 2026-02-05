// Agar Call Model hai toh uncomment kar lena: 
// const Call = require('../models/Call'); 

module.exports = (io, socket, onlineUsers, callState, activeCallPeer) => {
  
  // 1. START CALL
  socket.on("start_call", (data) => {
    console.log(`📞 Call Request: ${data.callerId} -> ${data.receiverId}`);

    const receiverSocketId = onlineUsers.get(data.receiverId);

    if (!receiverSocketId) {
      console.log(`⚠️ User ${data.receiverId} is OFFLINE`);
      socket.emit("call_failed", { reason: "User is offline" });
      return;
    }

    if (callState.has(data.receiverId)) {
      console.log(`⚠️ User ${data.receiverId} is BUSY`);
      socket.emit("call_failed", { reason: "User is busy" });
      return;
    }

    // Send Incoming Call
    io.to(receiverSocketId).emit("incoming_call", {
      from: data.callerId,
      offer: data.offer,
      callerName: data.callerName || "Unknown",
      callType: data.callType || 'audio' // audio/video
    });
  });

  // 2. ANSWER CALL
  socket.on("answer_call", (data) => {
    console.log(`✅ Call Accepted by ${data.senderId}`);
    const callerSocketId = onlineUsers.get(data.to);

    if (callerSocketId) {
      // Mark Busy
      callState.set(data.senderId, true);
      callState.set(data.to, true);

      // Track Peers
      activeCallPeer.set(socket.id, callerSocketId);
      activeCallPeer.set(callerSocketId, socket.id);

      io.to(callerSocketId).emit("call_accepted", {
        answer: data.answer,
      });
    } else {
       socket.emit("call_ended"); 
    }
  });

  // 3. ICE CANDIDATES (Connection)
  socket.on("ice_candidate", (data) => {
    const targetSocketId = onlineUsers.get(data.to);
    if (targetSocketId) {
      io.to(targetSocketId).emit("ice_candidate", {
        candidate: data.candidate,
      });
    }
  });

  // 4. END / REJECT CALL
  socket.on("end_call", (data) => {
    console.log(`🛑 Call Ended`);
    // Notify other user
    if (data.peerId) {
        const peerSocketId = onlineUsers.get(data.peerId);
        if (peerSocketId) io.to(peerSocketId).emit("call_ended");
    }
    
    // Clear State if IDs provided
    if(data.myId) callState.delete(data.myId);
    if(data.peerId) callState.delete(data.peerId);
  });

  socket.on("reject_call", (data) => {
     console.log(`🚫 Call Rejected`);
     const callerSocketId = onlineUsers.get(data.to);
     if (callerSocketId) io.to(callerSocketId).emit("call_rejected");
  });

  // 5. DISCONNECT
  socket.on("disconnect", () => {
    const peerSocketId = activeCallPeer.get(socket.id);
    if (peerSocketId) {
      io.to(peerSocketId).emit("call_ended");
      activeCallPeer.delete(peerSocketId);
      activeCallPeer.delete(socket.id);
    }
    // Note: User ID wise callState cleanup requires mapping socket.id -> userId
  });
};