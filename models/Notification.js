const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema(
  {
    recipientId: { 
      type: String, 
      required: true 
    }, // Jisko notification milegi (User UID)

    senderId: { 
      type: String 
    }, // Jisne bheji (System notifications ke liye null ho sakta hai)

    type: { 
      type: String, 
      enum: ['message', 'call', 'missed_call', 'system', 'job', 'alert', 'reaction'], // ✅ Saare types covered hain
      default: 'system' 
    }, 

    message: { 
      type: String, 
      required: true 
    }, // Notification ka main text (e.g., "You have a missed call")

    isRead: { 
      type: Boolean, 
      default: false 
    }, // Padh liya ya nahi (Red dot/Blue dot logic ke liye)

    relatedId: { 
      type: String 
    }, // Chat Room ID, Job ID, ya Call ID (Click karne par wahan le jayega)
  },
  { timestamps: true } // CreatedAt aur UpdatedAt automatic aayega
);

module.exports = mongoose.model('Notification', NotificationSchema);