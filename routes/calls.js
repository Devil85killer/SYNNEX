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
// 2. GET CALL HISTORY (With SMART Name Resolution)
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
    .sort({ createdAt: -1 }) // Latest call pehle
    // 🔥 MAGIC STEP: Saare possible name fields maang lo
    .populate('callerId', 'name username displayName email profilePic') 
    .populate('receiverId', 'name username displayName email profilePic');

    // 2. Data ko clean format mein convert karo
    const formattedCalls = calls.map(call => {
      // Agar user delete ho gaya ho toh safe object banao
      const caller = call.callerId || { _id: call.callerId };
      const receiver = call.receiverId || { _id: call.receiverId };

      // 🔥 UNIVERSAL NAME RESOLVER
      // Ye check karega: name hai? nahi toh displayName? nahi toh username? nahi toh Unknown.
      const callerName = caller.name || caller.displayName || caller.username || "Unknown User";
      const receiverName = receiver.name || receiver.displayName || receiver.username || "Unknown User";

      return {
        _id: call._id,
        // IDs
        callerId: caller._id,
        receiverId: receiver._id,
        
        // Resolved Names (Ab Frontend ko dimag nahi lagana padega)
        callerName: callerName, 
        receiverName: receiverName,
        
        // Pics
        callerPic: caller.profilePic || "",
        receiverPic: receiver.profilePic || "",

        // Extra details for safety
        callerDetails: caller,
        receiverDetails: receiver,

        type: call.type,
        status: call.status,
        timestamp: call.createdAt || call.timestamp || new Date()
      };
    });

    // 3. Response bhejo
    res.status(200).json({
      success: true,
      count: formattedCalls.length,
      data: formattedCalls 
    });

  } catch (err) {
    console.error("❌ Error fetching calls:", err);
    res.status(500).json({ success: false, data: [], error: err.message });
  }
});

module.exports = router;