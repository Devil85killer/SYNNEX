const mongoose = require('mongoose');

const CallSchema = new mongoose.Schema(
  {
    // ✅ FIX: 'String' hata kar 'ObjectId' kiya taaki .populate() kaam kare
    // Isse hi Call History mein "Unknown Number" ki jagah Asli Naam aayega
    callerId: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User', 
      required: true 
    },
    
    receiverId: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User', 
      required: true 
    },
    
    type: { 
      type: String, 
      enum: ['audio', 'video'], 
      default: 'audio' 
    },
    
    status: { 
      type: String, 
      enum: ['missed', 'accepted', 'rejected', 'ended', 'busy'], 
      default: 'missed' 
    },
    
    duration: { 
      type: Number, 
      default: 0 
    }, // Seconds mein (sirf 'ended' calls ke liye)
    
    startedAt: { 
      type: Date, 
      default: Date.now 
    },
    
    endedAt: { 
      type: Date 
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Call', CallSchema);