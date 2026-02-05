const express = require('express');
const router = express.Router();
const User = require('../models/User'); // Import path matches filename

router.post('/sync-user', async (req, res) => {
  const { uid, email, displayName, photoURL, fcmToken, rollNo } = req.body;
  try {
    let user = await User.findOne({ uid });
    if (user) {
      user.fcmToken = fcmToken;
      user.isOnline = true;
      if (rollNo) user.rollNo = rollNo;
      await user.save();
    } else {
      user = new User({ uid, email, displayName, photoURL, fcmToken, rollNo, isOnline: true });
      await user.save();
    }
    res.json({ success: true, user });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;