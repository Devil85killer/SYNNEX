const express = require('express');
const router = express.Router();
const Call = require('../models/Call'); // Ensure filename matches exactly (Call.js)

// ==========================================
// 1. LOG A NEW CALL (Call Start/End par hit hoga)
// ==========================================
router.post('/', async (req, res) => {
  console.log("📞 LOGGING CALL REQUEST:", req.body);
  
  const { callerId, receiverId, type, status, duration } = req.body;

  try {
    const newCall = new Call({
      callerId,
      receiverId,
      type: type || 'audio', // Default to audio if missing
      status: status || 'ended',
      duration: duration || 0
    });

    const savedCall = await newCall.save();
    
    res.status(200).json({ 
      success: true, 
      call: savedCall,
      data: savedCall // Backup key for safety
    });

  } catch (err) {
    console.error("❌ Error logging call:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 2. GET CALL HISTORY (User specific)
// ==========================================
router.get('/:userId', async (req, res) => {
  // console.log("📥 FETCHING CALLS FOR:", req.params.userId); // Logs kam karne ke liye comment kiya

  try {
    const calls = await Call.find({
      $or: [
        { callerId: req.params.userId }, 
        { receiverId: req.params.userId }
      ]
    }).sort({ createdAt: -1 }); // Latest call first
    
    // 🔥 UNIVERSAL FIX: Dono keys bhej rahe hain taaki Frontend crash na ho
    res.status(200).json({ 
      success: true, 
      calls: calls, // Standard key
      data: calls   // Backup key (agar purana code 'data' dhoond raha ho)
    });

  } catch (err) {
    console.error("❌ Error fetching calls:", err);
    // Error aane par bhi empty list bhejo taaki Red Screen na aaye
    res.status(500).json({ success: false, calls: [], data: [], error: err.message });
  }
});

module.exports = router;