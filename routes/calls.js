const express = require('express');
const router = express.Router();
const Call = require('../models/Call');
const User = require('../models/User'); 

// ==========================================
// 1. LOG A NEW CALL (Save to DB)
// ==========================================
router.post('/', async (req, res) => {
  try {
    const { callerId, receiverId, type, status, duration } = req.body;

    const newCall = new Call({
      callerId,
      receiverId,
      type: type || 'audio',
      status: status || 'ended',
      duration: duration || 0
    });

    const savedCall = await newCall.save();
    res.status(200).json({ success: true, data: savedCall });

  } catch (err) {
    console.error("❌ Error logging call:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 2. GET CALL HISTORY (With Smart Names)
// ==========================================
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const calls = await Call.find({
      $or: [{ callerId: userId }, { receiverId: userId }]
    })
    .sort({ createdAt: -1 }) // Get latest first
    .populate('callerId', 'name username displayName email profilePic') 
    .populate('receiverId', 'name username displayName email profilePic');

    const formattedCalls = calls.map(call => {
      // Safe handling if user is deleted
      const caller = call.callerId || { _id: call.callerId };
      const receiver = call.receiverId || { _id: call.receiverId };

      // SMART NAME RESOLVER: Checking multiple fields
      const callerName = caller.name || caller.displayName || caller.username || "Unknown User";
      const receiverName = receiver.name || receiver.displayName || receiver.username || "Unknown User";

      return {
        _id: call._id,
        callerId: caller._id,
        receiverId: receiver._id,
        callerName: callerName, 
        receiverName: receiverName,
        callerPic: caller.profilePic || "",
        receiverPic: receiver.profilePic || "",
        type: call.type,
        status: call.status,
        timestamp: call.createdAt || new Date()
      };
    });

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