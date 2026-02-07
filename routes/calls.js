const express = require('express');
const router = express.Router();
const Call = require('../models/Call');
const User = require('../models/User'); 

// 🔥 AUTO-HEAL FUNCTION: Ye user ko check karega aur agar nahi mila toh bana dega
const ensureUserExists = async (id, name, email, pic) => {
    if (!id) return;
    try {
        // MongoDB mein dhoondo, na mile toh naya banao (Upsert: true)
        // Hum purana data overwrite nahi karenge, bas missing fields bharenge
        await User.findByIdAndUpdate(
            id,
            { 
                $set: { 
                    name: name || "Alumni User",
                    displayName: name || "Alumni User",
                    username: name ? name.toLowerCase().replace(/\s/g, '') + "_" + id.substr(-4) : `user_${id.substr(-4)}`,
                    email: email || "",
                    profilePic: pic || ""
                } 
            },
            { upsert: true, new: true, setDefaultsOnInsert: true }
        );
        console.log(`✅ [Auto-Fix] User Synced in MongoDB: ${name || id}`);
    } catch (err) {
        console.error(`⚠️ [Auto-Fix Failed] Could not sync user ${id}:`, err.message);
    }
};

// ==========================================
// 1. LOG A NEW CALL (With Auto-Heal Logic)
// ==========================================
router.post('/', async (req, res) => {
  try {
    const { 
        callerId, callerName, callerEmail, callerPic, // Frontend se ye extra bhejna padega
        receiverId, receiverName, receiverEmail, receiverPic,
        type, status, duration 
    } = req.body;

    console.log("📞 Logging Call with Auto-Heal...");

    // 🔥 STEP 1: Pehle Users ko Fix karo (Background mein)
    // Ye wait karega taaki call save hone se pehle user DB mein aa jaye
    await Promise.all([
        ensureUserExists(callerId, callerName, callerEmail, callerPic),
        ensureUserExists(receiverId, receiverName, receiverEmail, receiverPic)
    ]);

    // 🔥 STEP 2: Ab Call Save karo
    const newCall = new Call({
      callerId,
      receiverId,
      type: type || 'audio',
      status: status || 'ended',
      duration: duration || 0
    });

    const savedCall = await newCall.save();
    
    // 🔥 STEP 3: Populate karke return karo
    await savedCall.populate('callerId', 'name username displayName profilePic');
    await savedCall.populate('receiverId', 'name username displayName profilePic');

    res.status(200).json({ success: true, data: savedCall });

  } catch (err) {
    console.error("❌ Error logging call:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 2. GET CALL HISTORY (With Smart Names & Debugging)
// ==========================================
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const calls = await Call.find({
      $or: [{ callerId: userId }, { receiverId: userId }]
    })
    .sort({ createdAt: -1 })
    .populate('callerId', 'name username displayName email profilePic') 
    .populate('receiverId', 'name username displayName email profilePic');

    const formattedCalls = calls.map(call => {
      // Safe handling if user is deleted or missing
      const caller = call.callerId || { _id: call.callerId };
      const receiver = call.receiverId || { _id: call.receiverId };

      // SMART NAME RESOLVER: Har kone mein naam dhoondo
      let callerName = "Unknown User";
      if (caller) {
          if (caller.name) callerName = caller.name;
          else if (caller.displayName) callerName = caller.displayName;
          else if (caller.username) callerName = caller.username;
          else if (caller.email) callerName = caller.email.split('@')[0];
      }

      let receiverName = "Unknown User";
      if (receiver) {
          if (receiver.name) receiverName = receiver.name;
          else if (receiver.displayName) receiverName = receiver.displayName;
          else if (receiver.username) receiverName = receiver.username;
          else if (receiver.email) receiverName = receiver.email.split('@')[0];
      }

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