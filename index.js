// =========================
// server.js
// =========================
require("dotenv").config();

const express = require("express");
const mongoose = require("mongoose");
const http = require("http");
const cors = require("cors");
const { Server } = require("socket.io");
const admin = require("firebase-admin"); // 🔥 Notification ke liye zaroori module

/* ================= FIREBASE ADMIN SETUP ================= */
// ⚠️ Ensure 'firebase-service-account.json' is in your backend root folder
const serviceAccount = require("./firebase-service-account.json"); 

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log("🔥 Firebase Admin SDK Initialized Successfully");
}

/* ================= APP & SERVER ================= */
const app = express();
const server = http.createServer(app);

/* ================= SOCKET.IO ================= */
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
});

/* ================= MIDDLEWARE ================= */
app.use(cors());
app.use(express.json()); // JSON data handle karne ke liye

/* ================= DATABASE CONNECTION ================= */
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => console.log("✅ MongoDB connected successfully"))
  .catch((err) => {
    console.error("❌ MongoDB error:", err.message);
    process.exit(1);
  });

/* ================= API ROUTES ================= */
console.log("📌 Registering API routes...");

// 🔐 AUTH (Token & FCM management)
app.use("/api/auth", require("./routes/auth"));
console.log("➡️  /api/auth registered");

// 💬 CHATS (Room management)
app.use("/api/chats", require("./routes/chats"));
console.log("➡️  /api/chats registered");

// 📨 MESSAGES (Chat history & Notification trigger)
app.use("/api/messages", require("./routes/messages"));
console.log("➡️  /api/messages registered");

// ❤️ REACTIONS
app.use("/api/reactions", require("./routes/reactions"));
console.log("➡️  /api/reactions registered");

// 📞 CALLS (Call logs & Call notifications)
app.use("/api/calls", require("./routes/calls")); 
console.log("➡️  /api/calls registered");

/* ================= SOCKET STATE ================= */
const onlineUsers = new Map();
const callState = new Map();
const activeCallPeer = new Map();

/* ================= SOCKET HANDLERS ================= */
io.on("connection", (socket) => {
  console.log("🟢 NEW SOCKET CONNECTION:", socket.id);

  // Chat socket logic
  require("./socket/chat.socket")(io, socket, onlineUsers);

  // Call socket logic
  require("./socket/call.socket")(
    io,
    socket,
    onlineUsers,
    callState,
    activeCallPeer
  );
});

/* ================= HEALTH CHECK & DOCS ================= */
app.get("/", (req, res) => {
  res.status(200).json({
    success: true,
    message: "Chatify Backend is Running 🚀",
    notificationStatus: admin.apps.length > 0 ? "Active" : "Inactive"
  });
});

/* ================= SERVER START ================= */
const PORT = process.env.PORT || 3000;
// '0.0.0.0' daalne se mobile connect ho payega
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server is live on port ${PORT}`);
  console.log(`✅ Mobile Access URL: http://10.67.251.188:${PORT}`);
});