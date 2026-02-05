const mongoose = require('mongoose');

const ChatSchema = new mongoose.Schema(
  {
    // ⚠️ IMPORTANT: Humne routes mein 'members' use kiya tha, isliye yahan bhi 'members' rakha hai.
    members: [{ type: String, required: true }], // User UIDs ka array
    
    lastMessage: { type: String },
    lastMessageTime: { type: Date, default: Date.now },

    // Future proofing (Agar Group Chat banani ho baad mein)
    isGroup: { type: Boolean, default: false },
    groupName: { type: String },
    groupAdmin: { type: String }, // Admin UID
  },
  { timestamps: true }
);

module.exports = mongoose.model('Chat', ChatSchema);