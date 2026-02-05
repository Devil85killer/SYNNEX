const mongoose = require('mongoose');

const ChatSchema = new mongoose.Schema(
  {
    // ⚠️ IMPORTANT: Routes mein humne 'members' query kiya tha, isliye ye match hona zaroori hai.
    members: [{ 
      type: String, 
      required: true 
    }], // User UIDs ka array (e.g. ["user1_id", "user2_id"])
    
    lastMessage: { 
      type: String 
    }, // Dashboard par "Last message..." dikhane ke liye
    
    lastMessageTime: { 
      type: Date, 
      default: Date.now 
    },

    // Future proofing (Agar baad mein Group Chat feature lana ho)
    isGroup: { 
      type: Boolean, 
      default: false 
    },
    groupName: { 
      type: String 
    },
    groupAdmin: { 
      type: String 
    }, // Admin UID
  },
  { timestamps: true }
);

module.exports = mongoose.model('Chat', ChatSchema);