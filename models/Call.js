const mongoose = require('mongoose');

const CallSchema = new mongoose.Schema(
  {
    callerId: { 
      type: String, 
      required: true 
    },
    receiverId: { 
      type: String, 
      required: true 
    },
    type: { 
      type: String, 
      enum: ['audio', 'video'], 
      default: 'audio' // Default audio rakhna safe rehta hai
    },
    status: { 
      type: String, 
      enum: ['missed', 'accepted', 'rejected', 'ended'], // 'ended' bhi add kiya normal calls ke liye
      default: 'missed' 
    },
    duration: { 
      type: Number, 
      default: 0 
    }, // Seconds mein
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