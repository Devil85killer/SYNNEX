const express = require('express');
const router = express.Router();
const Message = require('../models/Message');
const Chat = require('../models/chat'); // Make sure tumhare models folder mein file ka naam 'chat.js' hi ho

// ==========================================
// 1. SEND MESSAGE (Auto-Update Chat List)
// ==========================================
router.post('/', async (req, res) => {
  // 🔥 IMPORTANT: receiverId yahan zaroori hai
  const { roomId, senderId, receiverId, text, type, mediaUrl } = req.body;
  
  try {
    // A. Create New Message in 'messages' collection
    const newMessage = new Message({
      roomId,
      senderId,
      receiverId, 
      text,
      type: type || 'text',
      mediaUrl,
      status: 'sent',
      deletedForEveryone: false,
      isEdited: false
    });

    const savedMessage = await newMessage.save();

    // B. Update 'chats' collection (CRITICAL FIX)
    // Ye code ensure karega ki Sender aur Receiver dono 'members' list mein hon
    await Chat.findOneAndUpdate(
      { roomId: roomId }, 
      { 
        roomId: roomId, 
        lastMessage: type === 'image' ? '📷 Photo' : (type === 'audio' ? '🎤 Audio' : text), 
        lastMessageTime: new Date(),
        
        // $addToSet: Ye duplicate ID add nahi hone dega, par missing ID add kar dega
        $addToSet: { members: { $each: [senderId, receiverId] } } 
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

    // Messages ko time ke hisaab se sort karke bhejo
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
// 3. EDIT MESSAGE
// ==========================================
router.put('/:id', async (req, res) => {
  try {
    const { message } = req.body; 
    
    const updatedMsg = await Message.findByIdAndUpdate(
      req.params.id,
      { text: message, isEdited: true },
      { new: true } 
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
// 4. DELETE FOR EVERYONE
// ==========================================
router.delete('/:id', async (req, res) => {
  try {
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