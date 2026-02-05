const express = require('express');
const router = express.Router();
// Ensure karna ki model file ka naam sahi ho (Chat.js ya chat.js)
const Chat = require('../models/chat'); 
const User = require('../models/User');

// 1. Create or Get Existing Chat Room
router.post('/', async (req, res) => {
  const { senderId, receiverId } = req.body; 

  try {
    // Check agar in dono ke beech pehle se chat hai
    // $all ka matlab: Members array mein ye dono hone chahiye
    let chat = await Chat.findOne({
      members: { $all: [senderId, receiverId] }
    });

    if (chat) {
      // Agar chat mil gayi, wahi return kar do
      return res.status(200).json({ 
        success: true, 
        chat 
      });
    }

    // Agar nahi mili, toh nayi banao
    const newChat = new Chat({
      members: [senderId, receiverId]
    });

    const savedChat = await newChat.save();
    
    res.status(200).json({ 
      success: true, 
      chat: savedChat 
    });

  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 2. Get User's All Chats (Dashboard list ke liye)
router.get('/:userId', async (req, res) => {
  try {
    // Wo saare chats dhundo jisme ye user shaamil hai
    const chats = await Chat.find({
      members: { $in: [req.params.userId] }
    });
    
    res.status(200).json({ 
      success: true, 
      chats 
    });

  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;