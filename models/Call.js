const mongoose = require('mongoose');

const CallSchema = new mongoose.Schema(
  {
    // ✅ Caller ID (Link to User Collection)
    callerId: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User', // Ensure 'User' model exists and name matches exactly
      required: true 
    },
    
    // ✅ Receiver ID (Link to User Collection)
    receiverId: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User', 
      required: true 
    },
    
    // 📞 Call Type
    type: { 
      type: String, 
      enum: ['audio', 'video'], 
      default: 'audio' 
    },
    
    // 📊 Call Status
    status: { 
      type: String, 
      enum: ['missed', 'accepted', 'rejected', 'ended', 'busy'], 
      default: 'missed' 
    },
    
    // ⏳ Duration (in seconds)
    duration: { 
      type: Number, 
      default: 0 
    }, 
    
    // 🕒 Timestamps for specific logic
    startedAt: { 
      type: Date, 
      default: Date.now 
    },
    
    endedAt: { 
      type: Date 
    },
  },
  { timestamps: true } // Mongoose automatic createdAt & updatedAt
);

module.exports = mongoose.model('Call', CallSchema);