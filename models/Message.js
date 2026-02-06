const mongoose = require('mongoose');

const MessageSchema = new mongoose.Schema(
  {
    roomId: { 
      type: String, 
      required: true 
    }, // Socket room ID
    
    senderId: { 
      type: String, 
      required: true 
    }, // Sender UID
    
    receiverId: {
      type: String
    }, // Receiver UID (Optional but good for queries)
    
    text: { 
      type: String 
    },
    
    type: { 
      type: String, 
      enum: ['text', 'image', 'audio', 'video', 'file', 'call'], // ✅ 'audio' add kiya hai voice notes ke liye
      default: 'text' 
    },
    
    mediaUrl: { 
      type: String 
    }, // Photo/Audio/Video ka URL
    
    // 🔥 WHATSAPP 2.0 FEATURES
    status: {
      type: String,
      enum: ['sent', 'delivered', 'seen'],
      default: 'sent'
    }, // Blue Ticks logic yahan se chalega

    deletedForEveryone: {
      type: Boolean,
      default: false
    }, // Soft Delete ke liye

    isEdited: {
      type: Boolean,
      default: false
    }, // Edit label ke liye

    // 🔥 REACTION SUPPORT
    reactions: [
      {
        userId: { type: String },
        emoji: { type: String }
      }
    ]
  },
  { timestamps: true }
);

module.exports = mongoose.model('Message', MessageSchema);