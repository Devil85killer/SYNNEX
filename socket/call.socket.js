module.exports = (io, socket, onlineUsers, callState, activeCallPeer) => {
  
  // ----------------------------------------------------
  // 1. INITIATE CALL (Call Start Karna)
  // ----------------------------------------------------
  socket.on("start_call", (data) => {
    console.log(`📞 Start Call Request: ${data.callerId} -> ${data.receiverId}`);

    const receiverSocketId = onlineUsers.get(data.receiverId);

    // Case A: Receiver Offline hai
    if (!receiverSocketId) {
      console.log(`⚠️ User ${data.receiverId} is OFFLINE`);
      socket.emit("call_failed", { reason: "User is offline" });
      return;
    }

    // Case B: Receiver already kisi aur call par hai (BUSY)
    if (callState.has(data.receiverId)) {
      console.log(`⚠️ User ${data.receiverId} is BUSY`);
      socket.emit("call_failed", { reason: "User is busy" });
      return;
    }

    // Case C: Sab sahi hai -> Send Incoming Call
    io.to(receiverSocketId).emit("incoming_call", {
      from: data.callerId,
      offer: data.offer, // WebRTC SDP Offer
      callerName: data.callerName || "Unknown", // Optional: Name display ke liye
    });
  });

  // ----------------------------------------------------
  // 2. ANSWER CALL (Call Uthana)
  // ----------------------------------------------------
  socket.on("answer_call", (data) => {
    console.log(`✅ Call Accepted by ${data.senderId}`); // senderId yahan 'Receiver' hai jisne call uthaya

    const callerSocketId = onlineUsers.get(data.to); // 'to' is Original Caller ID

    if (callerSocketId) {
      // Dono users ko BUSY mark karo
      callState.set(data.senderId, true); // Receiver Busy
      callState.set(data.to, true);       // Caller Busy

      // Pair save karo (Kaun kisse baat kar raha hai - Disconnect handle karne ke liye)
      activeCallPeer.set(socket.id, callerSocketId); // My Socket -> Other Socket
      activeCallPeer.set(callerSocketId, socket.id); // Other Socket -> My Socket

      // Send Answer to Caller
      io.to(callerSocketId).emit("call_accepted", {
        answer: data.answer, // WebRTC SDP Answer
      });
    } else {
        // Agar Caller ne call karke turant app band kar diya
        socket.emit("call_ended"); 
    }
  });

  // ----------------------------------------------------
  // 3. REJECT CALL (Call Katna bina uthaye)
  // ----------------------------------------------------
  socket.on("reject_call", (data) => {
    console.log(`🚫 Call Rejected by ${data.senderId}`);
    const callerSocketId = onlineUsers.get(data.to);
    
    if (callerSocketId) {
      io.to(callerSocketId).emit("call_rejected");
    }
  });

  // ----------------------------------------------------
  // 4. ICE CANDIDATES (Connection Stable karna)
  // ----------------------------------------------------
  socket.on("ice_candidate", (data) => {
    // console.log("❄️ ICE Candidate received"); // Logs bharega isliye comment kiya hai
    const targetSocketId = onlineUsers.get(data.to);
    
    if (targetSocketId) {
      io.to(targetSocketId).emit("ice_candidate", {
        candidate: data.candidate,
      });
    }
  });

  // ----------------------------------------------------
  // 5. END CALL (Baat khatam karna)
  // ----------------------------------------------------
  socket.on("end_call", (data) => {
    console.log(`🛑 Call Ended by user`);
    
    const peerSocketId = onlineUsers.get(data.peerId);

    // Meri state clear karo
    // (Note: data.myId frontend se aana chahiye, ya hum socket se nikal lenge)
    // Filhal hum socket disconnect logic pe zyada rely karenge cleanup ke liye
    
    if (peerSocketId) {
      io.to(peerSocketId).emit("call_ended");
    }
    
    // Cleanup Maps (Optional: Frontend se explicit ID mile toh yahan bhi clear kar sakte ho)
    // Better logic is inside 'disconnect' event below
  });

  // ----------------------------------------------------
  // 6. HANDLE DISCONNECT (Agar internet band ho jaye)
  // ----------------------------------------------------
  socket.on("disconnect", () => {
    // Check karo agar ye banda kisi call par tha
    const peerSocketId = activeCallPeer.get(socket.id);

    if (peerSocketId) {
      console.log(`🔌 User disconnected during call. Notifying peer...`);
      
      // Dusre bande ko batao call kat gaya
      io.to(peerSocketId).emit("call_ended");

      // Maps clean karo
      activeCallPeer.delete(peerSocketId);
      activeCallPeer.delete(socket.id);
      
      // Call State (Busy) hatana thoda tricky hai bina userId ke, 
      // isliye hum 'activeCallPeer' map use karte hain socket track karne ke liye.
      // Par abhi ke liye basic notification kaafi hai.
    }
  });
};