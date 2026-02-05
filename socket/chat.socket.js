module.exports = (io, socket, onlineUsers) => {
  console.log(`💬 Chat socket initialized for: ${socket.id}`);

  // User online hone par handle karein
  socket.on("register_user", (userId) => {
    onlineUsers.set(userId, socket.id);
    console.log(`👤 User ${userId} is now online`);
  });

  // Message bhejne ke liye
  socket.on("send_message", (data) => {
    const receiverSocketId = onlineUsers.get(data.receiverId);
    if (receiverSocketId) {
      io.to(receiverSocketId).emit("receive_message", data);
    }
  });

  socket.on("disconnect", () => {
    console.log("❌ Chat socket disconnected");
  });
};