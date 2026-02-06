const express = require('express');
const router = express.Router();
const User = require('../models/User'); // ✅ Model path check kar lena
const jwt = require('jsonwebtoken'); 

// ==========================================
// 1. SYNC USER (Login/Register & Token Gen)
// ==========================================
router.post('/sync-user', async (req, res) => {
  // console.log("👤 SYNC USER REQ:", req.body.email); 

  const { uid, email, displayName, photoURL, fcmToken, rollNo, role } = req.body;

  try {
    // 1. Check if user exists
    let user = await User.findOne({ uid });

    if (user) {
      // ✅ Update existing user
      user.fcmToken = fcmToken; // Token refresh zaroori hai notifications ke liye
      user.isOnline = true;
      
      // Update details if provided
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
        isOnline: true,
        about: "Hey there! I am using Synnex." // Default Status
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
      process.env.JWT_SECRET || "SynnexSecretKey2026", 
      { expiresIn: "30d" }
    );

    // 3. SEND RESPONSE
    res.status(200).json({ 
      success: true, 
      user, 
      token // 🔥 Token bhej rahe hain
    });

  } catch (err) {
    console.error("❌ Auth Error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 2. GET ALL USERS (Search Feature Added)
// ==========================================
router.get('/users', async (req, res) => {
  try {
    const { search, except } = req.query;
    
    let query = {};

    // 🔍 Search Logic (Name or Email)
    if (search) {
      query = {
        $or: [
          { displayName: { $regex: search, $options: 'i' } }, // Case-insensitive match
          { email: { $regex: search, $options: 'i' } }
        ]
      };
    }

    // 🚫 Exclude Current User (Khud ko list mein na dikhaye)
    if (except) {
      query._id = { $ne: except };
    }

    const users = await User.find(query).select('-password'); // Password hata kar bhejo
    
    res.status(200).json({ success: true, users });

  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 3. GET SINGLE USER BY ID (Profile View)
// ==========================================
router.get('/user/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ success: false, message: "User not found" });
    
    res.status(200).json({ success: true, user });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;