const express = require('express');
const router = express.Router();
const Message = require('../models/Message'); // ✅ Message Model
const Chat = require('../models/chat');       // ✅ Chat Model (List update karne ke liye)

// ==========================================
// 1. SEND MESSAGE (API Fallback)
// ==========================================
router.post('/', async (req, res) => {
  const { roomId, senderId, text, type, mediaUrl, senderName, receiverName } = req.body;
  
  try {
    // A. Create New Message
    const newMessage = new Message({
      roomId,
      senderId,
      text, // Frontend se 'text' ya 'message' jo bhi aaye
      type: type || 'text',
      mediaUrl,
      status: 'sent', // Default Status
      deletedForEveryone: false,
      isEdited: false
    });

    const savedMessage = await newMessage.save();

    // B. Update Chat List (Last Message show karne ke liye)
    // Ye zaroori hai taaki home screen par "Last Message" update ho jaye
    await Chat.findOneAndUpdate(
      { roomId: roomId }, 
      { 
        roomId: roomId, 
        lastMessage: type === 'image' ? '📷 Photo' : (type === 'audio' ? '🎤 Audio' : text), 
        lastMessageTime: new Date(),
        // Members array update logic (Optional: add if not exists)
        $addToSet: { members: senderId } 
      },
      { upsert: true, new: true, setDefaultsOnInsert: true } 
    );
    
    res.status(200).json({ 
      success: true, 
      message: savedMessage 
    });

  } catch (err) {
    console.error("❌ Send Message Error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 2. GET MESSAGES (Chat History)
// ==========================================
router.get('/:roomId', async (req, res) => {
  try {
    const { roomId } = req.params;

    // Database se messages nikalo (Oldest First)
    const messages = await Message.find({ roomId: roomId })
      .sort({ createdAt: 1 }); 

    res.status(200).json({ 
      success: true, 
      messages: messages 
    });

  } catch (err) {
    console.error("❌ Get Messages Error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 3. EDIT MESSAGE (Naya Feature)
// ==========================================
router.put('/:id', async (req, res) => {
  try {
    const { message } = req.body; // Naya text
    
    const updatedMsg = await Message.findByIdAndUpdate(
      req.params.id,
      { text: message, isEdited: true },
      { new: true } // Return updated doc
    );

    if (!updatedMsg) {
      return res.status(404).json({ success: false, message: "Message not found" });
    }

    res.status(200).json({ 
      success: true, 
      message: updatedMsg 
    });

  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 4. DELETE FOR EVERYONE (Soft Delete)
// ==========================================
router.delete('/:id', async (req, res) => {
  try {
    // Database se permanent delete NAHI karenge
    // Bas 'deletedForEveryone' ko true kar denge
    const updatedMsg = await Message.findByIdAndUpdate(
      req.params.id,
      { deletedForEveryone: true },
      { new: true }
    );

    if (!updatedMsg) {
      return res.status(404).json({ success: false, message: "Message not found" });
    }

    res.status(200).json({ 
      success: true, 
      message: "Message deleted for everyone" 
    });

  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;