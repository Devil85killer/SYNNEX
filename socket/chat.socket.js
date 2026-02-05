const Message = require('../models/Message'); 
const Chat = require('../models/chat'); // Ensure casing matches your file name

module.exports = (io, socket, onlineUsers) => {

  // 1. Join Room
  socket.on("join-room", (roomId) => {
    socket.join(roomId);
    console.log(`✅ Socket ${socket.id} joined room: ${roomId}`);
  });

  // 2. Register User
  socket.on("register_user", (userId) => {
    onlineUsers.set(userId, socket.id);
    console.log(`👤 User Online: ${userId}`);
  });

  // 3. Send Message
  socket.on("sendMessage", async (data) => {
    console.log("📩 Message Received:", data);

    try {
      const { roomId, senderId, receiverId, message } = data;

      // --- STEP A: Save Message to DB (Messages Collection) ---
      const newMessage = new Message({
        roomId: roomId,
        senderId: senderId,
        receiverId: receiverId,
        text: message
      });

      const savedMsg = await newMessage.save();
      console.log("💾 Message Saved ID:", savedMsg._id);

      // --- STEP B: Update Chat List (Chatrooms Collection) ---
      // ✅ FIX: Ab ye error nahi dega kyunki Schema mein roomId hai
      await Chat.findOneAndUpdate(
        { roomId: roomId }, 
        { 
          roomId: roomId, // Ensure roomId is set on insert
          lastMessage: message, 
          lastMessageTime: new Date(),
          members: [senderId, receiverId] // Ensure members exist
        },
        { upsert: true, new: true, setDefaultsOnInsert: true } 
      ).catch(err => console.log("⚠️ Chat update error:", err.message));

      // --- STEP C: Real-time Send ---
      io.to(roomId).emit("receiveMessage", {
        senderId: senderId,
        text: message,
        createdAt: savedMsg.createdAt,
        _id: savedMsg._id
      });

    } catch (e) {
      console.log("❌ Socket Error:", e);
    }
  });
};