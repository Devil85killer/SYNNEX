const mongoose = require('mongoose');

const MessageSchema = new mongoose.Schema(
  {
    chatId: { type: String, required: true }, // Chat ID
    senderId: { type: String, required: true }, // Sender UID
    text: { type: String },
    type: { type: String, enum: ['text', 'image', 'video', 'file', 'call'], default: 'text' },
    mediaUrl: { type: String }, // Agar photo/video bheji toh yahan URL aayega
    readBy: [{ type: String }], // Kaun kaun padh chuka hai

    // 🔥 REACTION SUPPORT (Zaroori hai)
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