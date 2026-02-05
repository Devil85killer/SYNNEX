const express = require('express');
const router = express.Router();
const Message = require('../models/Message');

// 1. Add Message
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
    res.status(200).json(savedMessage);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 2. Get Messages of a Chat (FIXED RESPONSE FORMAT)
router.get('/:chatId', async (req, res) => {
  try {
    const messages = await Message.find({
      chatId: req.params.chatId
    });

    // ❌ Purana Code: res.status(200).json(messages);
    
    // ✅ Naya Code (Wrapper lagaya):
    res.status(200).json({ 
      success: true, 
      messages: messages 
    });

  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;