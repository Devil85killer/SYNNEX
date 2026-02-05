const express = require('express');
const router = express.Router();
const Message = require('../models/Message');

// 1. Add Message (API se send karne ke liye - Optional fallback)
router.post('/', async (req, res) => {
  // NOTE: 'roomId' use kar rahe hain taaki Socket code se match kare
  const { roomId, senderId, text, type, mediaUrl } = req.body;
  
  const newMessage = new Message({
    roomId,       // Database field name match hona chahiye
    senderId,
    text,
    type: type || 'text', // Default to text
    mediaUrl
  });

  try {
    const savedMessage = await newMessage.save();
    
    res.status(200).json({ 
      success: true, 
      message: savedMessage 
    });

  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 2. Get Messages of a Chat Room (History Load karna)
router.get('/:roomId', async (req, res) => {
  try {
    const { roomId } = req.params;

    // Database mein check karo
    const messages = await Message.find({
      roomId: roomId 
    }).sort({ createdAt: 1 }); // Oldest message first (Chat flow ke liye sahi hai)

    // Wrapper lagaya taaki frontend 'data.messages' read kar sake
    res.status(200).json({ 
      success: true, 
      messages: messages 
    });

  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;