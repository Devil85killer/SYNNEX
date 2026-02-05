const mongoose = require('mongoose');

const CallSchema = new mongoose.Schema(
  {
    callerId: { type: String, required: true },
    receiverId: { type: String, required: true },
    type: { type: String, enum: ['audio', 'video'], default: 'video' },
    status: { type: String, enum: ['missed', 'accepted', 'rejected'], default: 'missed' },
    duration: { type: Number, default: 0 },
    startedAt: { type: Date, default: Date.now },
    endedAt: { type: Date },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Call', CallSchema);