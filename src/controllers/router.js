var express = require('express');
var router = express.Router();
var sign = require('./frontend/sign')

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('./frontend/index');
});

router.get('/login', sign.showLogin);
router.post('/login',sign.login);

router.get('/register', sign.showRegister);
router.post('/register',sign.register);

router.get('/videochat',function(req,res,next){
    res.render('./frontend/videochat_demo');
});

module.exports = router;
 