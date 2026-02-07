const express = require('express');
const router = express.Router();
const Chat = require('../models/chat'); // Ensure model name matches file
const User = require('../models/User'); 

// 🔥 HELPER: Ye function chupchaap user ko check karega aur fix karega (Same as Calls)
const ensureUserExists = async (id, name, email, pic) => {
    if (!id) return;
    try {
        await User.findByIdAndUpdate(
            id,
            { 
                $set: { 
                    name: name || "Alumni User",
                    displayName: name || "Alumni User",
                    username: name ? name.toLowerCase().replace(/\s/g, '') + "_" + id.substr(-4) : `user_${id.substr(-4)}`,
                    email: email || "",
                    profilePic: pic || ""
                } 
            },
            { upsert: true, new: true, setDefaultsOnInsert: true }
        );
        console.log(`✅ [Chat Auto-Fix] User Synced: ${name || id}`);
    } catch (err) {
        console.error(`⚠️ [Chat Auto-Fix Failed] Could not sync user ${id}:`, err.message);
    }
};

// ==========================================
// 1. CREATE OR GET EXISTING CHAT ROOM (With Auto-Heal)
// ==========================================
router.post('/', async (req, res) => {
  // Frontend se ye extra data bhejna padega tabhi auto-fix chalega
  const { senderId, senderName, senderPic, receiverId, receiverName, receiverPic } = req.body; 

  try {
    // 🔥 STEP 1: Pehle Users ko Fix karo (Background mein)
    await Promise.all([
        ensureUserExists(senderId, senderName, "", senderPic),
        ensureUserExists(receiverId, receiverName, "", receiverPic)
    ]);

    // 🔥 STEP 2: Check agar chat pehle se hai
    let chat = await Chat.findOne({
      members: { $all: [senderId, receiverId] }
    });

    if (chat) {
      // Agar chat mil gayi, toh populate karke bhej do
      await chat.populate('members', 'name username displayName email profilePic');
      return res.status(200).json({ success: true, chat });
    }

    // 🔥 STEP 3: Agar nahi mili, toh nayi banao
    const newChat = new Chat({
      members: [senderId, receiverId],
      lastMessage: "", 
      lastMessageTime: new Date()
    });

    const savedChat = await newChat.save();
    
    // Optional: Room ID set karna
    savedChat.roomId = savedChat._id.toString();
    await savedChat.save();

    // 🔥 STEP 4: Populate karke return karo (Taaki turant naam dikhe)
    await savedChat.populate('members', 'name username displayName email profilePic');

    res.status(200).json({ success: true, chat: savedChat });

  } catch (err) {
    console.error("Create Chat Error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 2. GET USER'S ALL CHATS (Smart Population)
// ==========================================
router.get('/:userId', async (req, res) => {
  try {
    const chats = await Chat.find({
      members: { $in: [req.params.userId] }
    })
    .sort({ updatedAt: -1 }) 
    // 🔥 CRITICAL FIX: Sab kuch maang lo (name, displayName, username)
    .populate('members', 'name username displayName email profilePic role'); 

    // 🔥 Data Clean-up (Backend side par hi naam resolve kar lete hain)
    const formattedChats = chats.map(chat => {
        // Members ko process karo taaki 'name' field hamesha populated ho
        const processedMembers = chat.members.map(member => {
            const memObj = member.toObject ? member.toObject() : member;
            // Smart Name Logic
            memObj.name = memObj.name || memObj.displayName || memObj.username || "Unknown User";
            return memObj;
        });

        const chatObj = chat.toObject();
        chatObj.members = processedMembers;
        return chatObj;
    });

    res.status(200).json({ 
      success: true, 
      chats: formattedChats 
    });

  } catch (err) {
    console.error("Get Chats Error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;