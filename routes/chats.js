const express = require('express');
const router = express.Router();
const Chat = require('../models/chat'); // Ensure model name matches file (Capital C or small c)
const User = require('../models/User'); // Ensure model name matches file

// ======================================================
// 🔥 HELPER: Auto-Fix User (Magic Function)
// Ye function check karega ki user database mein hai ya nahi.
// Agar nahi hai, toh turant bana dega taaki Chat List khali na dikhe.
// ======================================================
const ensureUserExists = async (id, name, email, pic) => {
    if (!id) return;
    try {
        // ID valid honi chahiye (MongoDB ObjectId length check)
        if (id.length < 24) return; 

        await User.findByIdAndUpdate(
            id,
            { 
                $set: { 
                    name: name || "Alumni User",
                    displayName: name || "Alumni User",
                    // Username generate kar rahe hain agar missing hai
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

// ======================================================
// 1. CREATE OR GET CHAT (Jab Profile pe "Message" click ho)
// ======================================================
router.post('/', async (req, res) => {
    // Frontend se sender aur receiver dono ki details bhejna zaroori hai
    const { senderId, senderName, senderPic, receiverId, receiverName, receiverPic } = req.body; 

    try {
        // 🔥 STEP 1: Pehle dono Users ko database mein pakka karo
        await Promise.all([
            ensureUserExists(senderId, senderName, "", senderPic),
            ensureUserExists(receiverId, receiverName, "", receiverPic)
        ]);

        // 🔥 STEP 2: Check karo kya inke beech pehle se chat hai?
        let chat = await Chat.findOne({
            members: { $all: [senderId, receiverId] }
        });

        // Agar chat mil gayi, toh wahi wapas bhej do
        if (chat) {
            await chat.populate('members', 'name username displayName email profilePic');
            return res.status(200).json({ success: true, chat });
        }

        // 🔥 STEP 3: Agar nahi mili, toh nayi Chat banao
        const newChat = new Chat({
            members: [senderId, receiverId],
            lastMessage: "Start a conversation", 
            lastMessageTime: new Date(),
            roomId: `${senderId}___${receiverId}` // Unique Room ID
        });

        const savedChat = await newChat.save();

        // Populate karke return karo taaki Frontend pe naam dikhe
        await savedChat.populate('members', 'name username displayName email profilePic');

        res.status(200).json({ success: true, chat: savedChat });

    } catch (err) {
        console.error("Create Chat Error:", err);
        res.status(500).json({ success: false, error: err.message });
    }
});

// ======================================================
// 2. GET ALL CHATS (Home Screen List)
// ======================================================
router.get('/:userId', async (req, res) => {
    try {
        const userId = req.params.userId;

        // Wo saare chats laao jahan ye user member hai
        const chats = await Chat.find({
            members: { $in: [userId] }
        })
        .sort({ updatedAt: -1 }) // Latest updated chat sabse upar
        .populate('members', 'name username displayName email profilePic role'); 

        // 🔥 STEP 4: Smart Name Logic (Null Safety)
        // Kabhi kabhi database mein 'name' nahi hota, 'displayName' hota hai.
        // Ye code ensure karega ki Frontend ko hamesha ek valid naam mile.
        const formattedChats = chats.map(chat => {
            const processedMembers = chat.members.map(member => {
                // Member object ko safe access karo
                const memObj = member.toObject ? member.toObject() : member;
                
                // Fallback Logic: Name > DisplayName > Username > Unknown
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
        console.error("❌ Get Chats Error:", err);
        res.status(500).json({ success: false, error: err.message });
    }
});

module.exports = router;