const Message = require('../models/Message'); 
const Chat = require('../models/chat'); 

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
    
    // Optional: Check for undelivered messages and mark them delivered here
  });

  // 3. Send Message (Status: Sent)
  socket.on("sendMessage", async (data) => {
    console.log("📩 Message Received:", data);

    try {
      const { roomId, senderId, receiverId, message, type } = data;

      // --- STEP A: Save Message to DB ---
      const newMessage = new Message({
        roomId: roomId,
        senderId: senderId,
        receiverId: receiverId,
        text: message,
        type: type || 'text',
        status: 'sent', // Initially Sent (Single Grey Tick)
        deletedForEveryone: false,
        isEdited: false
      });

      const savedMsg = await newMessage.save();

      // --- STEP B: Update Chat List ---
      await Chat.findOneAndUpdate(
        { roomId: roomId }, 
        { 
          roomId: roomId, 
          lastMessage: type === 'image' ? '📷 Photo' : (type === 'audio' ? '🎤 Audio' : message), 
          lastMessageTime: new Date(),
          members: [senderId, receiverId] 
        },
        { upsert: true, new: true, setDefaultsOnInsert: true } 
      );

      // --- STEP C: Send to Room ---
      io.to(roomId).emit("receiveMessage", {
        _id: savedMsg._id,
        senderId: senderId,
        message: message,
        type: type || 'text',
        time: savedMsg.createdAt,
        status: 'sent',
        deletedForEveryone: false
      });

    } catch (e) {
      console.log("❌ Socket Error:", e);
    }
  });

  // 4. MARK AS DELIVERED (Double Grey Tick)
  // (Frontend tab emit karega jab message receive hoga)
  socket.on("markAsDelivered", async (data) => {
    const { roomId, messageId } = data;
    try {
       await Message.findByIdAndUpdate(messageId, { status: 'delivered' });
       // Sender ko batao ki deliver ho gaya
       socket.to(roomId).emit("message_status_update", { messageId, status: 'delivered' });
    } catch(e) { console.log(e); }
  });

  // 5. MARK AS SEEN (Blue Tick)
  // (Frontend tab emit karega jab chat screen open hogi)
  socket.on("markAsSeen", async (data) => {
    const { roomId, userId } = data; // userId wo hai jisne message dekha (Receiver)
    try {
        // Update all messages in this room sent by the OTHER person to 'seen'
        await Message.updateMany(
            { roomId: roomId, senderId: { $ne: userId }, status: { $ne: 'seen' } },
            { status: 'seen' }
        );

        // Poore room mein update bhejo (Sender ka tick blue ho jayega)
        io.to(roomId).emit("messages_seen", { roomId, userId });
        console.log(`🔵 All messages in ${roomId} marked as seen by ${userId}`);
    } catch(e) { console.log(e); }
  });

  // 6. DELETE FOR EVERYONE (Soft Delete)
  socket.on("delete_message", async (data) => {
    const { roomId, messageId } = data;
    try {
      // DB se delete nahi karenge, bas flag true karenge
      await Message.findByIdAndUpdate(messageId, { deletedForEveryone: true });

      // Real-time update bhejo
      io.to(roomId).emit("message_deleted", messageId);
      console.log(`🗑️ Message ${messageId} deleted for everyone`);
    } catch(e) { console.log(e); }
  });

  // 7. EDIT MESSAGE
  socket.on("edit_message", async (data) => {
    const { roomId, messageId, newText } = data;
    try {
      await Message.findByIdAndUpdate(messageId, { text: newText, isEdited: true });
      io.to(roomId).emit("message_edited", { messageId, newText });
    } catch(e) { console.log(e); }
  });
};