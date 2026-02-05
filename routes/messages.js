const express = require('express');
const router = express.Router();
const Message = require('../models/Message');

// 1. Add Message (Send)
router.post('/', async (req, res) => {
  const { chatId, senderId, text, type, mediaUrl } = req.body;
  
  const newMessage = new Message({
    chatId,
    senderId,
    text,
    type,       // text, image, video etc.
    mediaUrl    // agar file hai toh url
  });

  try {
    const savedMessage = await newMessage.save();
    
    // ✅ FIX: Wrapper lagaya (Consistency ke liye)
    res.status(200).json({ 
      success: true, 
      message: savedMessage 
    });

  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 2. Get Messages of a Chat (History)
router.get('/:chatId', async (req, res) => {
  try {
    const messages = await Message.find({
      chatId: req.params.chatId
    });

    // ✅ FIX: Wrapper lagaya (Taaki Frontend crash na ho)
    res.status(200).json({ 
      success: true, 
      messages: messages 
    });

  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;