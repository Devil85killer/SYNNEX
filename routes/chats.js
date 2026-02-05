const express = require('express');
const router = express.Router();
router.get('/', (req, res) => res.json({ message: "Chats route working" }));
module.exports = router;