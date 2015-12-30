require! <[express path serve-favicon cookie-parser body-parser ../config ./controllers/router]>
require! {'morgan':logger,'./models/dbinit': mongoinit}
app=express()
server = require('http').createServer app
ChatRTC = require('./ChatRTC').listen server

server.listen config.server.host, !->
    host = server.address!.address
    port = server.address!.port
    host is '0.0.0.0' && host = 'localhost'
    console.log '服务器启动，http://localhost%s:%s', host, port

/******************************************************
*
*服务器部分
*
*******************************************************/
ChatRTC.rtc.on 'new_connect',(socket)!->
    console.log '创建新连接'

ChatRTC.rtc.on 'remove_peer',(socketId)!->
    console.log socketId+'用户离开'

ChatRTC.rtc.on 'new_peer',(socket,room)!->
    console.log  '新用户' + socket.id + '加入房间' + room

ChatRTC.rtc.on 'socket_message',(socket,msg)!->
    console.log '接收到来自' + socket.id + '的新消息': + msg

ChatRTC.rtc.on 'ice_candidate',(socket,ice_candidate)!->
    console.log  '接收到来自' + socket.id + '的ICE Candidate'

ChatRTC.rtc.on 'offer',(socket,offer)!->
    console.log '接收到来自' + socket.id + '的Offer'

ChatRTC.rtc.on 'answer',(socket,answer)!->
    console.log '接收到来自' + socket.id + '的Answer'

ChatRTC.rtc.on 'error',(error)!->
    console.log '发生错误': + error.message

/******************************************************
*
*聊天服务器部分
*
*******************************************************/


# # 当前连接了聊天室的用户名
# usernames = {}
# numUsers = 0

# chatServer = require('http').Server(app)
# io = require('socket.io')(chatServer)

# chatServer.listen config.server.host, !->
#     host = chatServer.address!.address
#     port = chatServer.address!.port
#     host is '0.0.0.0' && host = 'localhost'
#     console.log 'listening at http://%s:%s', host, port

# io.on 'connection',(socket)->
#     console.log "a new user connected."
    
#     addedUser = false

#     # 用户上线
#     socket.on 'online',(username)->
#         socket.username = username
#         usernames[username] = username
#         ++numUsers
#         addedUser = true
#         socket.emit 'online',{numUsers:numUsers}

#     # 新消息 
#     socket.on 'new message',(msg)->
#         console.log "message:"+msg
#         io.emit 'new message',msg

#     # 用户下线
#     socket.on 'disconnect',->
#         console.log 'user disconnect'


/***************************************
*app
****************************************/
app.use(bodyParser.urlencoded({
    extended: true
}))
app.use(bodyParser.json())

#view engine setup
app.set('views',path.join(__dirname,'views'))
app.set('view engine', 'jade')

app.use(logger('dev'))
app.use(cookieParser())
app.use(express.static(path.join(__dirname, '../public')))
app.use(express.static(path.join(__dirname, 'views')))
app.use(express.static(path.join(__dirname, 'stylesheets')))
app.use(express.static(path.join(__dirname, 'controllers')))
app.use(express.static(path.join(__dirname, 'models')))

mongoinit!

#routes
app.use('/',router)

#catch 404 and forward to error handler
app.use (req,res,next)!->
    err=new Error('Not Found')
    err.status=404
    next(err)

#error handlers development error handler will print stacktrace
if app.get('env')=='development'
    app.use (err,req,res,next)!->
        res.status(err.status||500)
        res.render './error', do
            message: err.message
            error: err

#production error handler
#no stacktraces leaked to user
app.use (err,req,res,next)!->
    res.status err.status||500
    res.render './error',do
        message: err.message
        error: err

module.exports=app

