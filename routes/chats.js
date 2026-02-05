const express = require('express');
const router = express.Router();
const Chat = require('../models/chat'); // Model check kar lena (models/chat.js)
const User = require('../models/User');

// 1. Create or Get Chat Room
router.post('/', async (req, res) => {
  const { senderId, receiverId } = req.body; // chatifyUserIds (MongoDB _id)

  try {
    // Check agar chat pehle se hai
    let chat = await Chat.findOne({
      members: { $all: [senderId, receiverId] }
    });

    if (chat) {
      // ✅ FIX: Wrapper lagaya (Existing Chat)
      return res.status(200).json({ 
        success: true, 
        chat 
      });
    }

    // Naya Chat banao
    const newChat = new Chat({
      members: [senderId, receiverId]
    });

    const savedChat = await newChat.save();
    
    // ✅ FIX: Wrapper lagaya (New Chat)
    res.status(200).json({ 
      success: true, 
      chat: savedChat 
    });

  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 2. Get User's Chats
router.get('/:userId', async (req, res) => {
  try {
    const chats = await Chat.find({
      members: { $in: [req.params.userId] }
    });
    
    // ✅ FIX: Wrapper lagaya (Ab Chat List error nahi degi)
    res.status(200).json({ 
      success: true, 
      chats 
    });

  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;