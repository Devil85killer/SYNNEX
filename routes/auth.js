const express = require('express');
const router = express.Router();

// Login aur Register ke routes yahan aayenge
router.post('/login', (req, res) => {
    res.json({ message: "Login route working!" });
});

module.exports = router;