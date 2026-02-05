const express = require('express');
const router = express.Router();
const Chat = require('../models/chat'); // Matches small 'c' filename

// Create Chat
router.post('/create', async (req, res) => {
    const { userA, userB } = req.body;
    try {
        let chat = await Chat.findOne({ participants: { $all: [userA, userB] } });
        if (!chat) {
            chat = new Chat({ participants: [userA, userB] });
            await chat.save();
        }
        res.json({ success: true, chat });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get Chats
router.get('/:userId', async (req, res) => {
    try {
        const chats = await Chat.find({ participants: req.params.userId }).sort({ updatedAt: -1 });
        res.json({ success: true, chats });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;