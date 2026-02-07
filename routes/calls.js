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
    
    // Save karte hi populate karke return karo taaki turant naam dikhe
    await savedCall.populate('callerId', 'name username displayName profilePic');
    await savedCall.populate('receiverId', 'name username displayName profilePic');

    res.status(200).json({ success: true, data: savedCall });

  } catch (err) {
    console.error("❌ Error logging call:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 2. GET CALL HISTORY (With Smart Names & DEBUG LOGS)
// ==========================================
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    console.log(`\n🔍 [API] Fetching calls for UserID: ${userId}`);

    const calls = await Call.find({
      $or: [{ callerId: userId }, { receiverId: userId }]
    })
    .sort({ createdAt: -1 }) // Get latest first
    .populate('callerId', 'name username displayName email profilePic') 
    .populate('receiverId', 'name username displayName email profilePic');

    // 🔥 DEBUGGING BLOCK STARTS HERE 🔥
    if (calls.length > 0) {
        const latestCall = calls[0]; // Check only the latest call
        
        console.log("------------------------------------------------");
        console.log(`🔎 Checking Latest Call ID: ${latestCall._id}`);
        
        // Check Caller
        if (!latestCall.callerId) {
            console.error(`❌ [PROBLEM] Caller User Not Found in MongoDB! (ID was: ${latestCall.get('callerId')})`);
        } else {
            console.log(`✅ [OK] Caller Found: ${latestCall.callerId.name || latestCall.callerId.username}`);
        }

        // Check Receiver
        if (!latestCall.receiverId) {
            console.error(`❌ [PROBLEM] Receiver User Not Found in MongoDB! (ID was: ${latestCall.get('receiverId')})`);
        } else {
            console.log(`✅ [OK] Receiver Found: ${latestCall.receiverId.name || latestCall.receiverId.username}`);
        }
        console.log("------------------------------------------------");
    } else {
        console.log("⚠️ No calls found for this user yet.");
    }
    // 🔥 DEBUGGING BLOCK ENDS 🔥

    const formattedCalls = calls.map(call => {
      // Safe handling if user is deleted or missing
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