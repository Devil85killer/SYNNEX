const express = require('express');
const router = express.Router();
const Chat = require('../models/chat'); // ✅ Model ka naam sahi rakhna
const User = require('../models/User'); // ✅ User info populate karne ke liye

// ==========================================
// 1. CREATE OR GET EXISTING CHAT ROOM
// ==========================================
router.post('/', async (req, res) => {
  const { senderId, receiverId } = req.body; 

  try {
    // Check agar in dono ke beech pehle se chat hai
    const chat = await Chat.findOne({
      members: { $all: [senderId, receiverId] }
    });

    if (chat) {
      return res.status(200).json({ success: true, chat });
    }

    // Agar nahi mili, toh nayi banao
    // Note: 'roomId' hum members ki ID se bana sakte hain ya DB ki _id use kar sakte hain
    // Yahan hum DB ko apni unique _id banane dete hain
    const newChat = new Chat({
      members: [senderId, receiverId],
      lastMessage: "", // Shuru mein khali
      lastMessageTime: new Date()
    });

    const savedChat = await newChat.save();
    
    // Nayi chat mein 'roomId' field update kar do taaki Socket.io mein easy ho
    // (Optional: Agar tumhare model mein 'roomId' field hai)
    savedChat.roomId = savedChat._id.toString();
    await savedChat.save();

    res.status(200).json({ success: true, chat: savedChat });

  } catch (err) {
    console.error("Create Chat Error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 2. GET USER'S ALL CHATS (For Dashboard List)
// ==========================================
router.get('/:userId', async (req, res) => {
  try {
    // 1. Chats dhundo jisme user shamil hai
    // 2. Sort karo: Latest message sabse upar (updatedAt: -1)
    // 3. Populate: Saamne wale user ka Naam aur Photo nikalo
    const chats = await Chat.find({
      members: { $in: [req.params.userId] }
    })
    .sort({ updatedAt: -1 }) 
    .populate('members', 'username email profilePic'); // 🔥 Password mat bhejna

    res.status(200).json({ 
      success: true, 
      chats 
    });

  } catch (err) {
    console.error("Get Chats Error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;