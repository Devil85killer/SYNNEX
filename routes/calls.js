const express = require('express');
const router = express.Router();
const Call = require('../models/Call');
const User = require('../models/User'); // ✅ Ensure User model is imported

// ==========================================
// 1. LOG A NEW CALL (Save Call to DB)
// ==========================================
router.post('/', async (req, res) => {
  console.log("📞 LOGGING CALL:", req.body);

  try {
    const { callerId, receiverId, type, status, duration } = req.body;

    const newCall = new Call({
      callerId,
      receiverId,
      type: type || 'audio',
      status: status || 'ended',
      duration: duration || 0,
      timestamp: new Date()
    });

    const savedCall = await newCall.save();

    res.status(200).json({
      success: true,
      data: savedCall
    });

  } catch (err) {
    console.error("❌ Error logging call:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 2. GET CALL HISTORY (With Names & Photos)
// ==========================================
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    // 1. Database se Calls nikalo
    const calls = await Call.find({
      $or: [
        { callerId: userId },
        { receiverId: userId }
      ]
    })
    .sort({ timestamp: -1 }) // Latest call pehle
    // 🔥 MAGIC STEP: IDs ko asli User Data se badal do
    .populate('callerId', 'name email profilePic') // 'username' nahi 'name' use karo
    .populate('receiverId', 'name email profilePic');

    // 2. Data ko clean format mein convert karo (Frontend Crash rokne ke liye)
    const formattedCalls = calls.map(call => {
      // Agar user delete ho gaya ho toh crash na ho
      const caller = call.callerId || { _id: call.callerId, name: "Unknown User", profilePic: "" };
      const receiver = call.receiverId || { _id: call.receiverId, name: "Unknown User", profilePic: "" };

      return {
        _id: call._id,
        // IDs
        callerId: caller._id,
        receiverId: receiver._id,
        
        // Names (Direct access for Frontend)
        callerName: caller.name, 
        receiverName: receiver.name,
        
        // Pics
        callerPic: caller.profilePic,
        receiverPic: receiver.profilePic,

        type: call.type,
        status: call.status,
        timestamp: call.timestamp || call.createdAt
      };
    });

    // 3. Response bhejo
    res.status(200).json({
      success: true,
      data: formattedCalls // Frontend yahi 'data' key dhoond raha hai
    });

  } catch (err) {
    console.error("❌ Error fetching calls:", err);
    res.status(500).json({ success: false, data: [], error: err.message });
  }
});

module.exports = router;