const express = require('express');
const router = express.Router();
const User = require('../models/User'); // Abhi jo model banaya

// 🔄 SYNC USER (Login ke waqt call hoga)
router.post('/sync-user', async (req, res) => {
  const { uid, email, displayName, photoURL, fcmToken, rollNo } = req.body;

  try {
    // Check karo user pehle se hai ya nahi
    let user = await User.findOne({ uid });

    if (user) {
      // Agar hai, toh update karo (Token wagarah)
      user.fcmToken = fcmToken;
      user.isOnline = true;
      if (rollNo) user.rollNo = rollNo; // Roll no update agar aaya hai
      await user.save();
      return res.status(200).json({ success: true, message: "User updated", user });
    } else {
      // Naya user banao
      user = new User({ uid, email, displayName, photoURL, fcmToken, rollNo, isOnline: true });
      await user.save();
      return res.status(201).json({ success: true, message: "User created", user });
    }
  } catch (err) {
    console.error("Sync Error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;