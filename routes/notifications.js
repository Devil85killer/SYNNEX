const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification'); // ✅ Ensure 'models/Notification.js' exists

// 1. Create a Notification (Backend se ya API se)
router.post('/', async (req, res) => {
  const { recipientId, senderId, type, message, relatedId } = req.body;

  try {
    const newNotif = new Notification({
      recipientId,
      senderId,
      type,
      message,
      relatedId
    });

    const savedNotif = await newNotif.save();
    res.status(200).json(savedNotif);
  } catch (err) {
    console.error("Error creating notification:", err);
    res.status(500).json({ error: err.message });
  }
});

// 2. Get Notifications for a User
router.get('/:userId', async (req, res) => {
  try {
    // User ki saari notifications lao (Latest pehle)
    const notifications = await Notification.find({ 
      recipientId: req.params.userId 
    }).sort({ createdAt: -1 });

    res.status(200).json(notifications);
  } catch (err) {
    console.error("Error fetching notifications:", err);
    res.status(500).json({ error: err.message });
  }
});

// 3. Mark Notification as Read
router.put('/:id/read', async (req, res) => {
  try {
    const updatedNotif = await Notification.findByIdAndUpdate(
      req.params.id,
      { isRead: true },
      { new: true }
    );
    res.status(200).json(updatedNotif);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 4. Delete Notification
router.delete('/:id', async (req, res) => {
  try {
    await Notification.findByIdAndDelete(req.params.id);
    res.status(200).json({ message: "Notification deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;