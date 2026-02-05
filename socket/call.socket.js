module.exports = (io, socket, onlineUsers, callState, activeCallPeer) => {
  console.log(`📞 Call socket initialized for: ${socket.id}`);

  // Jab koi call shuru kare
  socket.on("start_call", (data) => {
    const receiverSocketId = onlineUsers.get(data.receiverId);
    if (receiverSocketId) {
      io.to(receiverSocketId).emit("incoming_call", {
        from: data.callerId,
        offer: data.offer,
      });
    }
  });

  // Call cut hone par
  socket.on("end_call", (data) => {
    const peerSocketId = onlineUsers.get(data.peerId);
    if (peerSocketId) {
      io.to(peerSocketId).emit("call_ended");
    }
  });
};