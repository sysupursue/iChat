/***************************************************
 *
 *聊天服务器
 *
 ***************************************************/

require! <[./app]>

# 当前连接了聊天室的用户名
usernames = {}
numUsers = 0

chatServer = require('http').Server(app)
io = require('socket.io')(chatServer)

chatServer.listen config.server.host, !->
    host = chatServer.address!.address
    port = chatServer.address!.port
    host is '0.0.0.0' && host = 'localhost'
    console.log 'listening at http://%s:%s', host, port

io.on 'connection',(socket)->
    console.log "a new user connected."
    
    addedUser = false

    # 用户上线
    socket.on 'online',(username)->
        socket.username = username
        usernames[username] = username
        ++numUsers
        addedUser = true
        socket.emit 'online',{numUsers:numUsers}

    # 新消息 
    socket.on 'new message',(msg)->
        console.log "message:"+msg
        io.emit 'new message',msg

    # 用户下线
    socket.on 'disconnect',->
        console.log 'user disconnect'