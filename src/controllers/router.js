var express = require('express');
var router = express.Router();
var sign = require('./frontend/sign')

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('./frontend/chating');
});

router.get('/login', sign.showLogin);
router.post('/login',sign.login);

router.get('/register', sign.showRegister);
router.post('/register',sign.register);

module.exports = router;
 