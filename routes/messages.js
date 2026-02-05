const express = require('express');
const router = express.Router();
const Message = require('../models/Message'); // Matches Capital 'M' filename

router.get('/:chatId', async (req, res) => {
    try {
        const messages = await Message.find({ chatId: req.params.chatId }).sort({ createdAt: 1 });
        res.json({ success: true, messages });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;