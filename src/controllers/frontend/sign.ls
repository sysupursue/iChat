/************************************************
 * 
 * 文件描述：该文件主要用于处理用户登录、注册、登出功能
 *
 ************************************************/

require! <[validator ../../common/validation]>
require! {'../../models/user':User}

# 
# 注册数据处理
# 
exports.register = function(req,res,next)
    username:validator.trim(req.body.username).toLowerCase()
    email:validator.trim(req.body.email).toLowerCase()
    password:validator.trim(req.body.password)
    repassword:validator.trim(req.body.repassword)

    console.log "username:"+username
    
    email-pattern = /^\w+@[a-zA-Z_]+?\.[a-zA-Z]{2,3}$/
    white-space-pattren = /\s/

    # 用户名验证
    if username isnt undefined
        if username.length < 3
            console.log '用户名长度至少为3位'
        if username.length > 15
            console.log  '用户名长度至多为15位'
    
    # 邮箱验证
    if email isnt undefined
        unless email-pattern.test email
            console.log '邮箱格式不正确'

    # 密码验证
    if password isnt undefined
        if password.length < 5 and password.length isnt 0
            console.log '密码长度至少为5位'
        if password.length < 5
            console.log  '密码长度至少为5位'
        if password.length > 16
            console.log '密码长度至多为16位'
        if (password.match white-sapce-pattren ) isnt null
            console.log '密码中不能包含空白字符'
    
    #密码确认
    if repassword isnt undefined
        if password isnt repassword
            console.log '两次输入的密码不一致'

    # mongoose api
    User.find-one $or:[{username:username},{email:email}],(err,user)->
        if err 
            console.log "数据库错误"
        # 数据库中存在用户
        if user
            if user.username is username
                console.log "用户名:"+username+"已被使用"
            if user.email is email
                console.log "邮箱:"+email+"已被注册"
        # 数据库中无此用户
        else 
            new-user = new User({username:username,email:email,password:password})
            new-user.save (err,user)->
                if err
                  console.log "存储用户信息时发生错误:"+err
                else
                    console.log "用户信息成功添加到数据库"

exports.showRegister = function(req,res)
    res.render('./frontend/register');

# 
#登录处理函数
# 
exports.login = function(req,res,next)
    username = validator.trim(req.body.username).toLowerCase()
    password = validator.trim(req.body.password)
    remember = validator.trim(req.body.remember)

    User.find {username:username,password:password} , (err,data)!->
        if err then console.log err 
        res.redirect "/"
        console.log "登录成功！"

exports.showLogin = function (req, res)
  res.render('./frontend/login');

