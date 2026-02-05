const mongoose = require('mongoose');

const ChatSchema = new mongoose.Schema(
  {
    // ✅ FIX: 'roomId' add kiya taaki backend error na de
    roomId: { 
      type: String, 
      required: true, 
      unique: true 
    },

    // Participants (User IDs)
    members: [{ 
      type: String, 
      required: true 
    }], 
    
    lastMessage: { 
      type: String,
      default: ""
    }, 
    
    lastMessageTime: { 
      type: Date, 
      default: Date.now 
    },

    // Future Proofing
    isGroup: { 
      type: Boolean, 
      default: false 
    },
    groupName: { type: String },
    groupAdmin: { type: String }, 
  },
  { timestamps: true }
);

module.exports = mongoose.model('Chat', ChatSchema);