const express = require('express');
const router = express.Router();
const Call = require('../models/Call'); // ✅ Ensure 'models/Call.js' exists

// 1. Log a New Call
router.post('/', async (req, res) => {
  console.log("📞 LOGGING CALL:", req.body); // Debug Log
  const { callerId, receiverId, type, status, duration } = req.body;

  try {
    const newCall = new Call({
      callerId,
      receiverId,
      type,
      status,
      duration
    });

    const savedCall = await newCall.save();
    
    res.status(200).json({ 
      success: true, 
      call: savedCall,
      data: savedCall // Backup key
    });

  } catch (err) {
    console.error("❌ Error logging call:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// 2. Get Call History (FIXED FOR NULL ERROR)
router.get('/:userId', async (req, res) => {
  console.log("📥 FETCHING CALLS FOR:", req.params.userId); // Debug Log

  try {
    const calls = await Call.find({
      $or: [
        { callerId: req.params.userId }, 
        { receiverId: req.params.userId }
      ]
    }).sort({ createdAt: -1 });
    
    console.log(`✅ Found ${calls.length} calls`);

    // 🔥 UNIVERSAL FIX: Bhejo 'calls' BHI aur 'data' BHI
    res.status(200).json({ 
      success: true, 
      calls: calls, // Agar app 'calls' dhoond raha hai
      data: calls   // Agar app 'data' dhoond raha hai
    });

  } catch (err) {
    console.error("❌ Error fetching calls:", err);
    // Even on error, send empty list to prevent App Crash
    res.status(500).json({ success: false, calls: [], data: [], error: err.message });
  }
});

module.exports = router;