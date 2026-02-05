const express = require('express');
const router = express.Router();
const Call = require('../models/Call'); // ✅ Ensure 'models/Call.js' exists

// 1. Log a New Call (Save Call History)
router.post('/', async (req, res) => {
  const { callerId, receiverId, type, status, duration } = req.body;

  try {
    const newCall = new Call({
      callerId,
      receiverId,
      type,
      status, // 'missed', 'accepted', etc.
      duration
    });

    const savedCall = await newCall.save();
    res.status(200).json(savedCall);
  } catch (err) {
    console.error("Error logging call:", err);
    res.status(500).json({ error: err.message });
  }
});

// 2. Get Call History for a User
router.get('/:userId', async (req, res) => {
  try {
    // Wo saare calls dhoondo jahan user ya toh Caller tha ya Receiver
    const calls = await Call.find({
      $or: [
        { callerId: req.params.userId }, 
        { receiverId: req.params.userId }
      ]
    }).sort({ createdAt: -1 }); // Latest pehle dikhao
    
    res.status(200).json(calls);
  } catch (err) {
    console.error("Error fetching calls:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;