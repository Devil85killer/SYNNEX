// =========================
// server.js (Final Optimized Version for Synnex)
// =========================
require("dotenv").config();

const express = require("express");
const mongoose = require("mongoose");
const http = require("http");
const cors = require("cors");
const os = require("os"); 
const { Server } = require("socket.io");
const admin = require("firebase-admin"); 

/* ================= FIREBASE ADMIN SETUP ================= */
try {
  // ⚠️ Ensure 'firebase-service-account.json' is in your backend root folder
  const serviceAccount = require("./firebase-service-account.json"); 
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log("🔥 Firebase Admin SDK Initialized Successfully");
  }
} catch (e) {
  console.log("⚠️ Firebase Warning: service-account file missing or invalid.");
}

/* ================= APP & SERVER ================= */
const app = express();
const server = http.createServer(app);

/* ================= SOCKET.IO SETUP (OPTIMIZED) ================= */
// Maine yahan connection stability settings add ki hain
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
  // 🔽 MOBILE STABILITY SETTINGS 🔽
  pingTimeout: 60000,   // 60s tak wait karega disconnect se pehle (Slow net pe zaroori hai)
  pingInterval: 25000,  // Har 25s main check karega connection
  connectionStateRecovery: {
    // Agar net gya aur wapas aaya, to session recover karega
    maxDisconnectionDuration: 2 * 60 * 1000,
    skipMiddlewares: true,
  }
});

/* ================= MIDDLEWARE ================= */
app.use(cors());
app.use(express.json()); 

/* ================= DATABASE CONNECTION ================= */
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => console.log("✅ MongoDB connected successfully"))
  .catch((err) => {
    console.error("❌ MongoDB error:", err.message);
    process.exit(1);
  });

/* ================= GLOBAL ERROR HANDLING (CRASH PREVENTION) ================= */
// Ye server ko band hone se bachayega agar choti-moti error aati hai
process.on('uncaughtException', (err) => {
  console.log('UNCAUGHT EXCEPTION! 💥 Logged only.');
  console.error(err);
});

process.on('unhandledRejection', (err) => {
  console.log('UNHANDLED REJECTION! 💥 Logged only.');
  console.error(err);
});

/* ================= API ROUTES ================= */
console.log("📌 Registering API routes...");

// 🔐 AUTH
app.use("/api/auth", require("./routes/auth"));
console.log("➡️  /api/auth registered");

// 💬 CHATS
app.use("/api/chats", require("./routes/chats"));
console.log("➡️  /api/chats registered");

// 📨 MESSAGES
app.use("/api/messages", require("./routes/messages"));
console.log("➡️  /api/messages registered");

// ❤️ REACTIONS
app.use("/api/reactions", require("./routes/reactions"));
console.log("➡️  /api/reactions registered");

// 📞 CALLS
app.use("/api/calls", require("./routes/calls")); 
console.log("➡️  /api/calls registered");

// 🔔 NOTIFICATIONS
app.use("/api/notifications", require("./routes/notifications"));
console.log("➡️  /api/notifications registered");

/* ================= SOCKET STATE ================= */
const onlineUsers = new Map();
const callState = new Map();
const activeCallPeer = new Map();

/* ================= SOCKET HANDLERS ================= */
io.on("connection", (socket) => {
  // Connection Debugging
  const userId = socket.handshake.query.userId;
  console.log(`🟢 NEW CONNECTION: ${socket.id} ${userId ? `(User: ${userId})` : ''}`);

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

  socket.on("disconnect", (reason) => {
    console.log(`🔴 Disconnected: ${socket.id} | Reason: ${reason}`);
  });
});

/* ================= HEALTH CHECK ================= */
app.get("/", (req, res) => {
  res.status(200).json({
    success: true,
    message: "Synnex Backend is Running 🚀",
    activeConnections: io.engine.clientsCount, // Kitne log connected hain
    notificationStatus: admin.apps.length > 0 ? "Active" : "Inactive"
  });
});

/* ================= SERVER START ================= */
const PORT = process.env.PORT || 3000;

// Helper function to get Local LAN IP
const getLocalIp = () => {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
};

server.listen(PORT, '0.0.0.0', () => {
  const localIp = getLocalIp();
  console.log(`\n🚀 Synnex Server is live on Port ${PORT}`);
  console.log(`-----------------------------------------------`);
  console.log(`🌐 Local Access:   http://localhost:${PORT}`);
  console.log(`📱 Mobile Access:  http://${localIp}:${PORT}`);
  console.log(`-----------------------------------------------`);
});