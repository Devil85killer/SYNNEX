const express = require('express');
const router = express.Router();
const User = require('../models/User'); // Model path check kar lena
const jwt = require('jsonwebtoken'); 

// ==========================================
// 1. SYNC USER (Login/Register & Token Gen)
// ==========================================
router.post('/sync-user', async (req, res) => {
  // console.log("👤 SYNC USER REQ:", req.body.email); // Debug log

  const { uid, email, displayName, photoURL, fcmToken, rollNo, role } = req.body;

  try {
    // 1. Check if user exists
    let user = await User.findOne({ uid });

    if (user) {
      // ✅ Update existing user
      user.fcmToken = fcmToken; // Token refresh zaroori hai notifications ke liye
      user.isOnline = true;
      // Agar naya data aaya hai to update karo, nahi to purana rakho
      if (displayName) user.displayName = displayName;
      if (photoURL) user.photoURL = photoURL;
      if (rollNo) user.rollNo = rollNo;
      if (role) user.role = role;
      
      await user.save();
    } else {
      // ✅ Create new user
      user = new User({ 
        uid, 
        email, 
        displayName, 
        photoURL, 
        fcmToken, 
        rollNo, 
        role: role || 'student', // Default role
        isOnline: true 
      });
      await user.save();
    }

    // 2. GENERATE JWT TOKEN
    // Ye token frontend use karega protected APIs call karne ke liye
    const token = jwt.sign(
      { 
        id: user._id,   // MongoDB ID
        uid: user.uid,  // Firebase UID
        role: user.role 
      }, 
      process.env.JWT_SECRET || "SynnexSecretKey2026", // .env nahi hua to fallback key
      { expiresIn: "30d" }
    );

    // 3. SEND RESPONSE
    res.status(200).json({ 
      success: true, 
      user, 
      token // 🔥 Token bhejna mat bhoolna
    });

  } catch (err) {
    console.error("❌ Auth Error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 2. GET ALL USERS (Chat List ke liye - Optional)
// ==========================================
// Agar tumhara 'alumni_chat_list.dart' yahan se users fetch kar raha hai:
router.get('/users', async (req, res) => {
  try {
    const users = await User.find({});
    res.status(200).json({ success: true, users });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;