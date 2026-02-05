module.exports = (io, socket, onlineUsers) => {
  socket.on("start_call", (data) => {
    const receiverSocketId = onlineUsers.get(data.receiverId);
    if (receiverSocketId) {
      io.to(receiverSocketId).emit("incoming_call", { from: data.callerId, offer: data.offer });
    }
  });

  socket.on("answer_call", (data) => {
    const callerSocketId = onlineUsers.get(data.to);
    if (callerSocketId) {
      io.to(callerSocketId).emit("call_accepted", { answer: data.answer });
    }
  });

  socket.on("ice_candidate", (data) => {
    const targetSocketId = onlineUsers.get(data.to);
    if (targetSocketId) {
      io.to(targetSocketId).emit("ice_candidate", { candidate: data.candidate });
    }
  });

  socket.on("end_call", (data) => {
    const peerSocketId = onlineUsers.get(data.peerId);
    if (peerSocketId) {
      io.to(peerSocketId).emit("call_ended");
    }
  });
};