const mongoose = require('mongoose');

const ChatSchema = new mongoose.Schema(
  {
    // ✅ FIX: Default function lagaya taaki agar frontend room ID na bheje toh crash na ho
    roomId: { 
      type: String, 
      default: () => new mongoose.Types.ObjectId().toString(),
      unique: true 
    },

    // ✅ FIX: 'String' ki jagah 'ObjectId' use kiya taaki .populate() kaam kare
    // Isse hi Chat List mein saamne wale ka Naam aur Photo dikhega
    members: [{ 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User', 
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

    // Future Proofing (Groups ke liye)
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