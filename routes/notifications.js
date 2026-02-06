const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification'); // ✅ Ensure path is correct

// ==========================================
// 1. CREATE A NOTIFICATION (Server-side Trigger or API)
// ==========================================
router.post('/', async (req, res) => {
  const { recipientId, senderId, type, message, relatedId } = req.body;

  try {
    const newNotif = new Notification({
      recipientId,
      senderId,
      type, // e.g., 'missed_call', 'new_message', 'reaction'
      message,
      relatedId,
      isRead: false
    });

    const savedNotif = await newNotif.save();

    res.status(200).json({ 
      success: true, 
      notification: savedNotif 
    });

  } catch (err) {
    console.error("❌ Error creating notification:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 2. GET NOTIFICATIONS FOR A USER
// ==========================================
router.get('/:userId', async (req, res) => {
  try {
    // User ki saari notifications lao (Latest pehle)
    const notifications = await Notification.find({ 
      recipientId: req.params.userId 
    }).sort({ createdAt: -1 });

    res.status(200).json({ 
      success: true, 
      notifications: notifications 
    });

  } catch (err) {
    console.error("❌ Error fetching notifications:", err);
    // Error mein bhi empty list bhejo taaki app crash na ho
    res.status(500).json({ success: false, notifications: [], error: err.message });
  }
});

// ==========================================
// 3. MARK NOTIFICATION AS READ
// ==========================================
router.put('/:id/read', async (req, res) => {
  try {
    const updatedNotif = await Notification.findByIdAndUpdate(
      req.params.id,
      { isRead: true },
      { new: true } // Returns the updated document
    );

    if (!updatedNotif) {
      return res.status(404).json({ success: false, message: "Notification not found" });
    }

    res.status(200).json({ 
      success: true, 
      notification: updatedNotif 
    });

  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 4. DELETE NOTIFICATION
// ==========================================
router.delete('/:id', async (req, res) => {
  try {
    const deletedNotif = await Notification.findByIdAndDelete(req.params.id);

    if (!deletedNotif) {
      return res.status(404).json({ success: false, message: "Notification not found" });
    }

    res.status(200).json({ 
      success: true, 
      message: "Notification deleted successfully" 
    });

  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;