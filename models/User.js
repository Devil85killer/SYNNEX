const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  uid: { 
    type: String, 
    required: true, 
    unique: true 
  },
  email: { 
    type: String, 
    required: true 
  },
  displayName: { 
    type: String 
  },
  photoURL: { 
    type: String 
  },
  rollNo: { 
    type: String 
  },
  role: { 
    type: String, 
    enum: ['student', 'alumni', 'admin'], 
    default: 'student' 
  }, // ✅ Auth logic ke liye ye zaroori hai
  fcmToken: { 
    type: String 
  }, // Notifications ke liye
  isOnline: { 
    type: Boolean, 
    default: false 
  },
  lastSeen: { 
    type: Date, 
    default: Date.now 
  },
}, { timestamps: true });

module.exports = mongoose.model('User', UserSchema);