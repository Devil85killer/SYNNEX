const express = require('express');
const router = express.Router();
const User = require('../models/User');
const jwt = require('jsonwebtoken'); // Token banane ke liye

// SYNC USER (Login/Register)
router.post('/sync-user', async (req, res) => {
  const { uid, email, displayName, photoURL, fcmToken, rollNo, role } = req.body;

  try {
    let user = await User.findOne({ uid });

    if (user) {
      // Update existing user
      user.fcmToken = fcmToken;
      user.isOnline = true;
      if (rollNo) user.rollNo = rollNo;
      if (role) user.role = role;
      await user.save();
    } else {
      // Create new user
      user = new User({ 
        uid, 
        email, 
        displayName, 
        photoURL, 
        fcmToken, 
        rollNo, 
        role: role || 'student', 
        isOnline: true 
      });
      await user.save();
    }

    // 🔥 TOKEN GENERATION (Ye missing tha)
    const token = jwt.sign(
      { id: user._id, uid: user.uid, role: user.role }, 
      process.env.JWT_SECRET || "SynnexSecretKey2026", 
      { expiresIn: "30d" }
    );

    res.status(200).json({ 
      success: true, 
      user, 
      token // ✅ Token bhej diya
    });

  } catch (err) {
    console.error("Auth Error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;