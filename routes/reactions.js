const express = require('express');
const router = express.Router();
const Message = require('../models/Message');

router.post('/', async (req, res) => {
  const { messageId, userId, emoji } = req.body;
  try {
    const message = await Message.findById(messageId);
    if (!message) return res.status(404).json({ success: false });

    const existingIndex = message.reactions.findIndex(r => r.userId === userId && r.emoji === emoji);
    if (existingIndex > -1) message.reactions.splice(existingIndex, 1);
    else message.reactions.push({ userId, emoji });

    await message.save();
    res.status(200).json({ success: true, message });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

module.exports = router;