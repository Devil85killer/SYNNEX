const mongoose = require('mongoose');

const ChatSchema = new mongoose.Schema({
  participants: [{ type: String }], // User UIDs store karenge
  lastMessage: { type: String },
  lastMessageTime: { type: Date, default: Date.now },
}, { timestamps: true });

module.exports = mongoose.model('Chat', ChatSchema);