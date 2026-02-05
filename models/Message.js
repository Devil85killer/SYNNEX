const mongoose = require('mongoose');

const MessageSchema = new mongoose.Schema({
  chatId: { type: mongoose.Schema.Types.ObjectId, ref: 'Chat' },
  senderId: { type: String, required: true },
  text: { type: String },
  type: { type: String, default: 'text' },
  readBy: [{ type: String }],
}, { timestamps: true });

module.exports = mongoose.model('Message', MessageSchema);