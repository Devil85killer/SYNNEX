const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema(
  {
    recipientId: { 
      type: String, 
      required: true 
    }, // Jisko notification milegi (User UID)

    senderId: { 
      type: String 
    }, // Jisne bheji (Optional - System notifications ke liye null ho sakta hai)

    type: { 
      type: String, 
      enum: ['message', 'call', 'system', 'job', 'alert'], // 'alert' bhi add kar diya safety ke liye
      default: 'system' 
    }, 

    message: { 
      type: String, 
      required: true 
    }, // Notification ka main text

    isRead: { 
      type: Boolean, 
      default: false 
    }, // Padh liya ya nahi

    relatedId: { 
      type: String 
    }, // Chat ID ya Job ID (click karne par wahan le jayega)
  },
  { timestamps: true } // CreatedAt automatic aayega
);

module.exports = mongoose.model('Notification', NotificationSchema);