const express = require('express');
const router = express.Router();
const Call = require('../models/Call'); // ✅ Call Model

// ==========================================
// 1. LOG A NEW CALL (Call Start/End/Missed par hit hoga)
// ==========================================
router.post('/', async (req, res) => {
  console.log("📞 LOGGING CALL REQUEST:", req.body);
  
  const { callerId, receiverId, type, status, duration } = req.body;

  try {
    const newCall = new Call({
      callerId,
      receiverId,
      type: type || 'audio', // Default audio
      status: status || 'ended', // missed, rejected, ended
      duration: duration || 0
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

// ==========================================
// 2. GET CALL HISTORY (User specific)
// ==========================================
router.get('/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;

    const calls = await Call.find({
      $or: [
        { callerId: userId }, 
        { receiverId: userId }
      ]
    })
    .sort({ createdAt: -1 }) // Latest call pehle
    // 🔥 POPULATE: Naam aur Photo nikalne ke liye
    // Note: Make sure 'Call' model mein 'ref: User' laga ho
    .populate('callerId', 'username profilePic email') 
    .populate('receiverId', 'username profilePic email');
    
    res.status(200).json({ 
      success: true, 
      calls: calls, // Standard key
      data: calls   // Backup key
    });

  } catch (err) {
    console.error("❌ Error fetching calls:", err);
    res.status(500).json({ success: false, calls: [], data: [], error: err.message });
  }
});

module.exports = router;