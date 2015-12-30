WebSocketServer = require('ws').Server
UUID = require('node-uuid')
events = require('events')
util = require('util')

errorCb = (rtc)->
    return (error)!->
        if error
            rtc.emit "error",error

ChatRTC = !->
    console.log "事件:" + events.EventEmitter
    @.sockets = []
    @.rooms = {}
    
    @.on '__join',(data,socket) !->
        console.log "当前接入服务器的连接数目:" + @.sockets.length

        console.log "__join事件由客户端socket readyState变成open 触发" 
        console.log "socket.onopen 发送过来的数据" + data 
        
        var i , m , curSocket , curRoom
        ids = []
        room = data.room || "__default"

        curRoom = @.rooms[room] = @.rooms[room] || []
        console.log "客户端加入的房间：" + room + "当前房间数：" + curRoom.length + ": curRoom" + curRoom + "rooms:" + @.rooms

        console.log "这里执行了吗？"

        i = 0 
        while i < curRoom.length , i++ then
            curSocket = curRoom[i]
            console.log "我已深入内部。"
            if curSocket.id == socket.id
                continue
            ids.push curSocket.id
            curSocket.send JSON.stringify({
                "eventName":"_new_peer",
                "data":{
                    "socketId":socket.id
                }
            }),errorCb

        console.log "好像真没执行啊！"

        curRoom.push socket
        socket.room = room

        socket.send JSON.stringify({
            "eventName":"_peers",
            "data":{
                "connections":ids,
                "you":socket.id
            }
        }) , errorCb

        @.emit 'new_peer',socket,room

    @.on '__ice_candidate',(data,socket) !->
        soc = @.getSocket data.socketId

        if soc 
            soc.send JSON.stringify({
                "eventName":"_ice_candidate",
                "data":{
                    "label":data.label,
                    "candidate":data.candidate,
                    "socketId":socket.id
                }
            }) , errorCb

            @.emit 'ice_candidate',socket,data

    @.on '__offer',(data,socket)!->
        soc = @.getSocket data.socketId
        console.log "***接收到__offer事件***" + socket.id + "***" +soc

        if soc 
            soc.send JSON.stringify({
                "eventName":"_offer",
                "data":{
                    "sdp":data.sdp,
                    "socketId":socket.id
                }
            }) , errorCb
        @.emit 'offer',socket,data

    @.on '__answer',(data,socket)!->
        soc = @.getSocket data.socketId

        if soc
            soc.send JSON.stringify({
                "eventName":"_answer",
                "data":{
                    "sdp":data.sdp,
                    "socketId":socket.id
                }
            }) , errorCb

            @.emit 'answer',socket,data

util.inherits ChatRTC,events.EventEmitter

ChatRTC::addSocket = (socket)!->
    @.sockets.push socket

ChatRTC::removeSocket = (socket)!->
    i = @.sockets.indexOf socket
    room = socket.room

    @.sockets.splice i,1
    if room
        i = @.rooms[room].indexOf socket
        @.rooms[room].splice i,1
        if @.rooms[room].length == 0
            delete @.rooms[room]

ChatRTC::broadcast = (data,errorCb)!->
    for i from @sockets.length til 0 by -1
        @.sockets[i].send data,errorCb

ChatRTC::broadcastInRoom = (room,data,errorCb)!->
    curRoom = @.rooms[room]
    if curRoom
        for i from curRoom.length til 0 by -1
            curRoom[i].send data,errorCb

ChatRTC::getRooms = ->
    rooms = []
    var room 
    for room of @.rooms
        rooms.push room
    return rooms

ChatRTC::getSocket = (id)->
    console.log "这里是getSocket函数"
    var curSocket
    if !@.socket
        return
    i = @.sockets.length
    while i > 0 , i-- then
    # for i from @.sockets.length til 0 by -1
        console.log "这里是getSocket函数**********执行了吗"
        curSocket = @.sockets[i]
        if id == curSocket.id
            return curSocket
    return 0 

ChatRTC::init = (socket)!->
    thats = this
    socket.id = UUID.v4()
    console.log "UUID:" + socket.id
    thats.addSocket socket

    # 为新连接绑定事件处理器
    socket.on 'message',(data)!->
        json = JSON.parse data
        if json.eventName
            thats.emit json.eventName,json.data,socket
        else
            thats.emit 'socket_message',socket,data

    # 连接关闭后从ChatRTC实例中移除连接，并通知其他连接
    socket.on 'close',!->
        var i , m , curRoom
        room = socket.curRoom
        if room
            curRoom = thats.rooms[room]
            for i from curRoom.length til 0 by -1
                if curRoom[i].id == socket.id
                    continue
                curRoom[i].send JSON.stringify({
                    "eventName":"_remove_peer",
                    "data":{
                        "socketId":socket.id
                    }
                }) , errorCb
        thats.removeSocket socket
        thats.emit 'remove_peer',socket.id , thats
    thats.emit 'new_connect',socket

module.exports.listen = (server)->
    var ChatRTCServer
    if typeof server == 'number'
        ChatRTCServer = new WebSocketServer({
            port:server
        })
    else
        ChatRTCServer = new WebSocketServer ({
            server:server
            })
    ChatRTCServer.rtc = new ChatRTC()
    # errorCb = errorCb(ChatRTCServer.rtc)
    ChatRTCServer.on 'connection',(socket)!->
        @.rtc.init socket

    console.log '视频聊天服务器已开启'
    
    return ChatRTCServer
