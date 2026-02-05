const mongoose = require('mongoose');

const MessageSchema = new mongoose.Schema(
  {
    roomId: { 
      type: String, 
      required: true 
    }, // ✅ FIXED: Socket code is field ko 'roomId' ke naam se dhundta hai
    
    senderId: { 
      type: String, 
      required: true 
    }, // Sender UID
    
    receiverId: {
      type: String
    }, // Optional: Future use ke liye
    
    text: { 
      type: String 
    },
    
    type: { 
      type: String, 
      enum: ['text', 'image', 'video', 'file', 'call'], 
      default: 'text' 
    },
    
    mediaUrl: { 
      type: String 
    }, // Agar photo/video bheji toh yahan URL aayega
    
    readBy: [{ 
      type: String 
    }], // Kaun kaun padh chuka hai

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