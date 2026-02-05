const express = require('express');
const router = express.Router();
router.get('/', (req, res) => res.json({ message: "Reactions route working" }));
module.exports = router;