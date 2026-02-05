const Message = require('../models/Message'); 
// Agar tere paas Chat model file ka naam small 'c' se hai toh wahi rakhna
const Chat = require('../models/chat'); 

module.exports = (io, socket, onlineUsers) => {

  // 1. Join Room (Ye zaroori hai taaki user specific chat sun sake)
  socket.on("join-room", (roomId) => {
    socket.join(roomId);
    console.log(`✅ Socket ${socket.id} joined room: ${roomId}`);
  });

  // 2. Register User (Online status track karne ke liye)
  socket.on("register_user", (userId) => {
    onlineUsers.set(userId, socket.id);
    console.log(`👤 User Online: ${userId}`);
  });

  // 3. Send Message (Flutter 'sendMessage' bhej raha hai)
  socket.on("sendMessage", async (data) => {
    console.log("📩 Message Received:", data);

    try {
      // Data destructuring (Flutter se yahi keys aa rahi hain)
      const { roomId, senderId, receiverId, message } = data;

      // --- STEP A: Save Message to DB ---
      const newMessage = new Message({
        roomId: roomId, // Flutter 'roomId' bhej raha hai
        senderId: senderId,
        receiverId: receiverId,
        text: message
      });

      const savedMsg = await newMessage.save();
      console.log("💾 Message Saved ID:", savedMsg._id);

      // --- STEP B: Update Chat List (Last Message) ---
      // Hum koshish karenge ki Chat collection update ho jaye
      if (Chat) {
        // Find by roomId (assuming Chat model has roomId field)
        // Agar tere Chat model mein _id hi roomId hai, toh findByIdAndUpdate use kar
        await Chat.findOneAndUpdate(
          { roomId: roomId }, 
          { 
            lastMessage: message, 
            lastMessageTime: new Date() 
          },
          { new: true, upsert: true } // Create new if not exists
        ).catch(err => console.log("⚠️ Chat update skipped:", err.message));
      }

      // --- STEP C: Real-time Send (Room Logic) ---
      // Room logic sabse reliable hai chat screen ke liye
      io.to(roomId).emit("receiveMessage", {
        senderId: senderId,
        text: message,
        createdAt: savedMsg.createdAt,
        _id: savedMsg._id
      });

      // (Optional) Agar user Room mein nahi hai lekin Online hai (Notification ke liye)
      // const receiverSocketId = onlineUsers.get(receiverId);
      // if (receiverSocketId) {
      //    io.to(receiverSocketId).emit("notification", { text: message, senderId });
      // }

    } catch (e) {
      console.log("❌ DB Error inside socket:", e);
    }
  });
};