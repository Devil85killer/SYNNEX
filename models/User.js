const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  uid: { type: String, required: true, unique: true }, // Firebase UID
  email: { type: String, required: true },
  displayName: { type: String },
  photoURL: { type: String },
  rollNo: { type: String }, // Agar student login hai
  fcmToken: { type: String }, // Notification ke liye zaroori
  isOnline: { type: Boolean, default: false },
  lastSeen: { type: Date, default: Date.now },
}, { timestamps: true });

module.exports = mongoose.model('User', UserSchema);