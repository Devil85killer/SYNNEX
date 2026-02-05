const express = require('express');
const router = express.Router();
const Message = require('../models/Message'); // ✅ Message Model zaroori hai

// 1. Toggle Reaction (Add or Remove)
router.post('/', async (req, res) => {
  const { messageId, userId, emoji } = req.body;

  try {
    const message = await Message.findById(messageId);

    if (!message) {
      return res.status(404).json({ message: "Message not found" });
    }

    // Check karo ki user ne pehle se same reaction diya hai kya?
    const existingReactionIndex = message.reactions.findIndex(
      (r) => r.userId === userId && r.emoji === emoji
    );

    if (existingReactionIndex > -1) {
      // ✅ Agar reaction hai, toh REMOVE karo (Toggle Off)
      message.reactions.splice(existingReactionIndex, 1);
    } else {
      // ✅ Agar reaction nahi hai, toh ADD karo (Toggle On)
      message.reactions.push({ userId, emoji });
    }

    // Save updated message
    const updatedMessage = await message.save();
    
    // Note: Agar tum Socket.io use kar rahe ho, toh yahan 'emit' kar sakte ho
    // taaki doosre user ko turant reaction dikh jaye.
    
    res.status(200).json(updatedMessage);

  } catch (err) {
    console.error("Reaction Error:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;