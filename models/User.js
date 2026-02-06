const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  uid: { 
    type: String, 
    required: true, 
    unique: true 
  }, // Firebase UID
  email: { 
    type: String, 
    required: true 
  },
  displayName: { 
    type: String 
  },
  photoURL: { 
    type: String,
    default: "" 
  },
  rollNo: { 
    type: String 
  },
  role: { 
    type: String, 
    enum: ['student', 'alumni', 'admin', 'teacher'], 
    default: 'student' 
  }, 
  
  // 🔥 Notifications & Chat Features
  fcmToken: { 
    type: String 
  }, 
  isOnline: { 
    type: Boolean, 
    default: false 
  },
  lastSeen: { 
    type: Date, 
    default: Date.now 
  },
  
  // 📝 WhatsApp Style Status (About)
  about: {
    type: String,
    default: "Hey there! I am using Synnex."
  }

}, { timestamps: true });

module.exports = mongoose.model('User', UserSchema);