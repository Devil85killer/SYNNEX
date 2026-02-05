const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema(
  {
    recipientId: { type: String, required: true }, // Jisko notification milegi
    senderId: { type: String }, // Jisne bheji (optional)
    type: { type: String, enum: ['message', 'call', 'system', 'job'], default: 'system' }, // Kis type ki hai
    message: { type: String, required: true }, // Notification ka text
    isRead: { type: Boolean, default: false }, // Padh liya ya nahi
    relatedId: { type: String }, // Chat ID ya Job ID (click karne par wahan le jayega)
  },
  { timestamps: true }
);

module.exports = mongoose.model('Notification', NotificationSchema);