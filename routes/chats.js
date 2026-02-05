const express = require('express');
const router = express.Router();
const Chat = require('../models/chat'); // Model ka naam check kar lena (file: models/chat.js)
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
      return res.status(200).json(chat);
    }

    // Naya Chat banao
    const newChat = new Chat({
      members: [senderId, receiverId]
    });

    const savedChat = await newChat.save();
    res.status(200).json(savedChat);
  } catch (err) {
    res.status(500).json(err);
  }
});

// 2. Get User's Chats
router.get('/:userId', async (req, res) => {
  try {
    const chats = await Chat.find({
      members: { $in: [req.params.userId] }
    });
    res.status(200).json(chats);
  } catch (err) {
    res.status(500).json(err);
  }
});

module.exports = router;