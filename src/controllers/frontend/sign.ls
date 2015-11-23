# 
# 文件描述：该文件主要用于处理用户登录、注册、登出功能
# 
require! <[validator]>
require! {'../../models/user':User}

exports.showLogin = function (req, res)
  res.render('./frontend/login');

#登录处理函数
exports.login = function(req,res,next)
    username = validator.trim(req.body.username).toLowerCase()
    password = validator.trim(req.body.password)
    remember = validator.trim(req.body.remember)

    User.find {username:username,password:password} , (err,data)!->
        if err then console.log err 
        console.log "登录成功！"
        res.send data


exports.showRegister = function(req,res)
    res.render('./frontend/register');

# 注册数据处理
exports.register = function(req,res,next)
    username = validator.trim(req.body.username).toLowerCase();
    email = validator.trim(req.body.email).toLowerCase();
    password = validator.trim(req.body.password);
    repassword = validator.trim(req.body.repassword);

    if password != repassword then console.log "password not equal"
    newuser = new User({username:username,email:email,password:password});
    console.log "This is newUser " + newuser.username

    User.find {username=" "},(err,docs)-> console.log docs
    
    newuser.save (err)!->
        if err then return console.log "用户存入数据库时错误"+err
        res.send(newuser)
        console.log "成功插入数据库中"