const Message = require('../models/Message'); // Matches Capital 'M'
const Chat = require('../models/chat');       // Matches small 'c'

module.exports = (io, socket, onlineUsers) => {
  socket.on("register_user", (userId) => {
    onlineUsers.set(userId, socket.id);
    console.log(`👤 User Online: ${userId}`);
  });

  socket.on("send_message", async (data) => {
    // 1. DB Save
    try {
      if(data.chatId){
          const newMessage = new Message({ 
            chatId: data.chatId, 
            senderId: data.senderId, 
            text: data.message 
          });
          await newMessage.save();
          
          await Chat.findByIdAndUpdate(data.chatId, { 
            lastMessage: data.message, 
            lastMessageTime: new Date() 
          });
      }
    } catch (e) { console.log("DB Error:", e); }

    // 2. Real-time Send
    const receiverSocketId = onlineUsers.get(data.receiverId);
    if (receiverSocketId) {
      io.to(receiverSocketId).emit("receive_message", data);
    }
  });
};