const Message = require('../models/Message'); 
const Chat = require('../models/chat'); 

module.exports = (io, socket, onlineUsers) => {

  // 1. JOIN ROOM (User enters a chat screen)
  socket.on("join-room", (roomId) => {
    try {
      if (!roomId) return;
      socket.join(roomId);
      console.log(`✅ Socket ${socket.id} joined room: ${roomId}`);
    } catch (e) {
      console.error("❌ Error joining room:", e);
    }
  });

  // 2. REGISTER USER (User comes online)
  socket.on("register_user", (userId) => {
    try {
      onlineUsers.set(userId, socket.id);
      console.log(`👤 User Online: ${userId}`);
    } catch (e) {
      console.error("❌ Error registering user:", e);
    }
  });

  // 3. SEND MESSAGE (Main Chat Logic)
  socket.on("sendMessage", async (data) => {
    console.log("📩 Message Payload:", data);

    try {
      const { roomId, senderId, receiverId, message, type } = data;

      if (!roomId || !senderId || !receiverId) {
        console.log("⚠️ Missing required fields in sendMessage");
        return;
      }

      // --- STEP A: Save Message to DB ---
      const newMessage = new Message({
        roomId: roomId,
        senderId: senderId,
        receiverId: receiverId,
        text: message,
        type: type || 'text',
        status: 'sent', // Single Grey Tick
        deletedForEveryone: false,
        isEdited: false
      });

      const savedMsg = await newMessage.save();

      // --- STEP B: Update Chat List (Recent Chats) ---
      await Chat.findOneAndUpdate(
        { roomId: roomId }, 
        { 
          roomId: roomId, 
          lastMessage: type === 'image' ? '📷 Photo' : (type === 'audio' ? '🎤 Audio' : message), 
          lastMessageTime: new Date(),
          members: [senderId, receiverId],
          // Unread count logic frontend handle karega ya alag API se hoga
        },
        { upsert: true, new: true, setDefaultsOnInsert: true } 
      );

      // --- STEP C: Send to Receiver (Real-time) ---
      // 'io.to' bhejta hai sabko (Sender + Receiver) taaki sender ko bhi confirmation mile
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
      console.error("❌ Send Message Error:", e);
      // Optional: Emit error back to sender
      socket.emit("message_error", { error: "Failed to send message" });
    }
  });

  // 4. MARK AS DELIVERED (Double Grey Tick)
  socket.on("markAsDelivered", async (data) => {
    try {
      const { roomId, messageId } = data;
      await Message.findByIdAndUpdate(messageId, { status: 'delivered' });
      
      // Notify Sender that message is delivered
      socket.to(roomId).emit("message_status_update", { messageId, status: 'delivered' });
    } catch(e) { 
      console.error("❌ Mark Delivered Error:", e); 
    }
  });

  // 5. MARK AS SEEN (Blue Tick)
  socket.on("markAsSeen", async (data) => {
    const { roomId, userId } = data; 
    try {
        // Update DB: Mark all messages from the OTHER person as seen
        await Message.updateMany(
            { roomId: roomId, senderId: { $ne: userId }, status: { $ne: 'seen' } },
            { status: 'seen' }
        );

        // Notify Room (Sender will see Blue Ticks)
        io.to(roomId).emit("messages_seen", { roomId, userId });
        
        // Log clean rakha hai
        console.log(`🔵 Messages seen in room: ${roomId}`);
    } catch(e) { 
      console.error("❌ Mark Seen Error:", e); 
    }
  });

  // 6. DELETE FOR EVERYONE
  socket.on("delete_message", async (data) => {
    const { roomId, messageId } = data;
    try {
      await Message.findByIdAndUpdate(messageId, { deletedForEveryone: true });
      io.to(roomId).emit("message_deleted", messageId);
      console.log(`🗑️ Message Deleted: ${messageId}`);
    } catch(e) { 
      console.error("❌ Delete Error:", e); 
    }
  });

  // 7. EDIT MESSAGE
  socket.on("edit_message", async (data) => {
    const { roomId, messageId, newText } = data;
    try {
      await Message.findByIdAndUpdate(messageId, { text: newText, isEdited: true });
      io.to(roomId).emit("message_edited", { messageId, newText });
    } catch(e) { 
      console.error("❌ Edit Error:", e); 
    }
  });
  
  // 8. TYPING INDICATOR (Optional but good for UX)
  socket.on("typing", (data) => {
    const { roomId, userId } = data;
    socket.to(roomId).emit("user_typing", { userId });
  });

  socket.on("stop_typing", (data) => {
    const { roomId, userId } = data;
    socket.to(roomId).emit("user_stop_typing", { userId });
  });
};