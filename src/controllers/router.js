var express = require('express');
var router = express.Router();

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('./frontend/index');
});

router.get('/login', function(req, res, next) {
  res.render('./frontend/login');
});

router.get('/register', function(req, res, next) {
  res.render('./frontend/register');
});

module.exports = router;
