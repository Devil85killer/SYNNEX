const express = require('express');
const router = express.Router();
const Message = require('../models/Message'); // File: models/Message.js

// 1. Add Message
router.post('/', async (req, res) => {
  const { chatId, senderId, text } = req.body;
  
  const newMessage = new Message({
    chatId,
    senderId,
    text
  });

  try {
    const savedMessage = await newMessage.save();
    res.status(200).json(savedMessage);
  } catch (err) {
    res.status(500).json(err);
  }
});

// 2. Get Messages of a Chat
router.get('/:chatId', async (req, res) => {
  try {
    const messages = await Message.find({
      chatId: req.params.chatId
    });
    res.status(200).json(messages);
  } catch (err) {
    res.status(500).json(err);
  }
});

module.exports = router;