ChatRTC = ->
    PeerConnection = window.PeerConnection || window.webkitPeerConnection || window.webkitRTCPeerConnection ||window.mozPeerConnection
    URL = window.URL || window.webkitURL || window.msURL || window.oURL
    getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.msGetUserMedia || navigator.mozGetUserMedia
    nativeRTCIceCandidate = window.RTCIceCandidate || window.mozRTCIceCandidate
    nativeRTCSessionDescription = window.mozRTCSessionDescription || window.RTCSessionDescription 
    moz = !!navigator.mozGetUserMedia

    # Google stun 服务器
    iceServer = {
        "iceServers":[{
            "url":"stun:stun.l.google.com:19302"
            }]
    };

    packetSize = 1000

    /******************************************************
    *
    *事件处理器
    *
    *******************************************************/
    EventEmitter = !->
        @.events = {}

     # 绑定事件函数
    EventEmitter::on = (eventName,callback)!->
        @.events[eventName] = @.events[eventName] || []
        @.events[eventName].push callback

    # 触发事件函数
    EventEmitter::emit = (eventName,_) !->
        events = @.events[eventName]
        args = Array::slice.call arguments,1

        console.log "EventEmitter:" + eventName
        if !events
            return;

        for i from 0 til events.length 
            events[i].apply null,args

    /******************************************************
    *
    *流及通信信道部分
    *
    *******************************************************/

    chatrtc = !->
        # 本地media stream
        @localMediaStream = null
        # 所在的房间
        @room = ""
        # 接收文件时用于暂存接收文件
        @fileData = {}
        # 本地websocket连接
        @socket = null
        # 本地socket.id，由后台服务器创建
        @me = null
        # 保存与本地相连的peer connection , 键为socket.id ，值为PeerConnection类型
        @peerConnections = {}
        # 保存所有与本地连接的socket的id
        @connections = []
        # 初始时需要构建链接的数目
        @numStreams = 0
        # 初始时已经连接的数目
        @initializedStreams = 0
        # 保存所有的data channel，键为socket id，值通过PeerConnection实例的createChannel创建
        @dataChannels = {}
        # 保存所有发文件的data channel及其发文件状态
        @fileChannels = {}
        # 保存所有接受到的文件
        @receiveFiles = {}

    #继承自事件处理器，提供绑定事件和触发事件的功能
    chatrtc.prototype = new EventEmitter()


    /******************************************************
    *
    *服务器连接部分
    *
    *******************************************************/


    # 本地连接信道，信道为websocket
    chatrtc::connect = (server,room) !->
        console.log "Client:客户端信道连接已发起"
        thats = @
        room = room || ""
        socket = @socket = new WebSocket(server)

        console.log "客户端socket状态："+socket.readyState
        socket.onopen = !->
            socket.send JSON.stringify({
                "eventName":"__join",
                "data":{
                    "room":room
                }
            })
            thats.emit "socket_opened",socket


        socket.onmessage = (message)!->
            json = JSON.parse message.data
            console.log "eventName:" + json.eventName + "   data:" + json.data
            if json.eventName
                thats.emit json.eventName,json.data
            else
                thats.emit "socket_receive_message",socket,json

        socket.onerror = (error)!->
            thats.emit "socket_error",error,socket

        # 关闭所有连接，并重置相关参数
        socket.onclose = (data)!->
            # thats.localMediaStream.close()
            pcs = thats.peerConnections
            for i from pcs.length to 0 by -1
                thats.closePeerConnection pcs[i]
            thats.peerConnections = []
            thats.dataChannels = {}
            thats.fileChannels = {}
            thats.connections = []
            thats.fileData = {}
            thats.emit "socket_closed",socket

        @on '_peers',(data)!->
            # 获取所有服务器上的连接
            thats.connections = data.connections
            console.log "connections的长度为:"+thats.connections.length
            thats.me = data.you
            console.log "_peers事件触发，并发射get_peers、与connected事件"
            thats.emit "get_peers",thats.connections
            thats.emit "connected",socket

        @on '_ice_candidate',(data)!->
            candidate = new nativeRTCIceCandidate data
            pc = thats.peerConnections data.socketId
            pc.addIceCandidate candidate
            thats.emit 'get_ice_candidate',candidate

        @on '_new_peer',(data)!->
            thats.connections.push data.socketId
            pc = thats.createPeerConnection data.socketId
            console.log "连接建立；为新连接添加本地流" + pc
            pc.addStream thats.localMediaStream
            console.log "本地刘添加完毕，触发new_peer事件" + thats.localMediaStream
            thats.emit 'new_peer',data.socketId

        @on '_remove_peer',(data)!->
            sendId
            thats.closePeerConnection thats.peerConnections[data.socketId]
            delete thats.peerConnections[data.socketId]
            delete thats.dataChannels[data.socketId]
            for sendId of thats.fileChannels[data.socketId]
                thats.emit 'send_file_error',new Error "Connection has been closed",data.socketId,sendId,thats.fileChannels[data.socketId][sendId].file
            delete thats.fileChannels[data.socketId]
            thats.emit "remove_peer",data.socketId

        @on '_offer',(data)!->
            console.log "-----接收到_offer事件"
            thats.receiveOffer data.socketId,data.sdp
            thats.emit "get_offer",data

        @on '_answer',(data)!->
            thats.receiveAnswer data.socketId , data.sdp
            thats.emit "get_answer",data

        @on 'send_file_error',(error,socketId,sendId,file)!->
            thats.cleanSendFile sendId,socketId

        @on 'receive_file_error',(error,sendId)!->
            thats.cleanReceiveFile sendId

        @on 'ready',!->
            thats.createPeerConnections()
            thats.addStreams()
            thats.addDataChannels()
            thats.sendOffers()


    /******************************************************
    *
    *流处理部分
    *
    *******************************************************/


    # 创建本地流
    chatrtc::createStream = (options)!->
        console.log "chatrtc:创建本地流"
        thats = @
        options.video = !!options.video
        options.audio = !!options.audio

        if getUserMedia
            @.numStreams++
            getUserMedia.call navigator,options,(stream)!->
                        thats.localMediaStream = stream
                        thats.initializedStreams++
                        thats.emit "stream_created",stream
                        if thats.initializedStreams == thats.numStreams
                            console.log "initializedStreams === numStreams 触发ready事件开始"
                            thats.emit "ready"
                            console.log "initializedStreams === numStreams 触发ready事件结束"

            ,(error)!->
                thats.emit "stream_create_error",error
        else
            thats.emit "stream_create_error",new Error "WebRTC is not yet supported in this brower."

    # 将本地流添加到所有的PeerConnection实例中
    chatrtc::addStreams = !->
        console.log "这里是addStreams函数内部" + @.peerConnections
        for connection of @.peerConnections
            console.log "addStreams函数内部的connection" + @.peerConnections[connection]
            @.peerConnections[connection].addStream(@.localMediaStream)

    # 将流绑定到video标签上用于输出
    chatrtc::attachStream = (stream,domId)!->
        element = document.getElementById domId
        if navigator.mozGetUserMedia
            element.mozSrcObject = stream
            element.play()
        else
            element.src = URL.createObjectURL stream
        element.src = URL.createObjectURL stream


    /******************************************************
    *
    *点对点连接部分
    *
    *******************************************************/


    # 创建与其他用户的PeerConnections
    chatrtc::createPeerConnections = !->
        console.log "chatrtc:创建多个PeerConnection连接"
        # var i , m
        i = 0
        m = @.connections.length
        while i < m , i++ then
            @.createPeerConnection @.connections[i]

        # for i from 0 til @.connections.length
        #     @.createPeerConnection @.connections[i]

    # 创建单个PeerConnection连接
    chatrtc::createPeerConnection = (socketId)->
        console.log "chatrtc:创建单个PeerConnection连接"
        thats = @
        pc = new PeerConnection iceServer
        @.peerConnections[socketId] = pc

        pc.onicecandidate = (evt)!->
            if evt.candidate
                thats.socket.send JSON.stringify ({
                    "eventName":"__ice_candidate",
                    "data":{
                        "label":evt.candidate.sdpMlineIndex,
                        "candidate":evt.candidate.candidate,
                        "socketId":socketId
                    }
                })
            thats.emit "pc_get_ice_candidate",evt.candidate,socketId,pc

        pc.onopen = !->
            thats.emit "pc_opened",socketId,pc

        pc.onaddstream = (evt)!->
            console.log "客户端：添加流事件"
            thats.emit "pc_add_stream",evt.stream,socketId,pc

        pc.ondatachannel = (evt)!->
            thats.addDataChannel socketId,evt.channel
            thats.emit "pc_add_data_channel",evt.channel,socketId,pc
        return pc

    # 关闭PeerConnection连接
    chatrtc::closePeerConnection = (pc)!->
        if !pc 
            return
        pc.close


    /******************************************************
    *
    *信令交换部分
    *
    *******************************************************/


    # 向所有的PeerConnection发送Offer类型信令
    chatrtc::sendOffers = !->
        var pc
        thats = @
        console.log "---sendOffers函数内部---"
        # 创建offer成功的回调函数
        pcCreateOfferCbGen = (pc,socketId)->
            (session_desc)!->
                console.log "createOffer函数内部"
                pc.setLocalDescription session_desc
                thats.socket.send JSON.stringify({
                    "eventName":"__offer",
                    "data":{
                        "sdp":session_desc,
                        "socketId":socketId
                        "info":"事件触发成功"
                    }
                })

        # 创建offer失败的回调函数
        pcCreateOfferErrorCb = (error)!->
            console.log error

        # 为每个连接创建offer
        i = 0
        while i < @.connections.length , i++ then
        # for i from 0 til @.connections.length 
            pc = @.peerConnections[@.connections[i]]
            pc.createOffer(pcCreateOfferCbGen(pc , @.connections[i]),pcCreateOfferErrorCb)

    # 接收到得offer类型信令后作为回应返回answer类型信令
    chatrtc::receiveOffer = (socketId,sdp)!->
        pc = @.peerConnections[socketId]
        @.sendAnswer socketId,sdp

    # 发送answer类型信令
    chatrtc::sendAnswer= (socketId,sdp)!->
        pc = @.peerConnections socketId
        thats = @
        pc.setRemoteDescription new nativeRTCSessionDescription sdp
        pc.createAnswer (session_desc)!->
            pc.setLocalDescription session_desc
            thats.socket.send JSON.stringify({
                "eventName":"__answer",
                "data":{
                    "socketId":socketId,
                    "sdp":session_desc
                }
            })
        ,(error)!->
            console.log error

    # 接收到answer类型信令后将对方的session描述写入PeerConnection中
    chatrtc::receiveAnswer = (socketId,sdp)!->
        pc = @.peerConnections[socketId]
        pc.setRemoteDescription new nativeRTCSessionDescription sdp


    /******************************************************
    *
    *数据通道连接部分
    *
    *******************************************************/

    # 消息广播
    chatrtc::broadcast = (message)!->
        var socketId
        for socketId of @.dataChannels
            @.sendMessage message,socketId

    # 发送消息方法
    chatrtc::sendMessage = (message,socketId) !->
        if @.dataChannels[socketId].readyState.toLowerCase() == 'open'
            @.dataChannels[socketId].send JSON.stringify({
                type:"__msg",
                data:message
            })

    # 为所有的PeerConnections创建Data channel
    chatrtc::addDataChannels = !->
        console.log "数据通道创建"
        var connection
        for connection of @.peerConnections
            @.createDataChannel(connection)

    # 对某一个PeerConnction创建Data Channel
    chatrtc::createDataChannel = (socketId,label)!->
        console.log "————createDataChannel函数内部----"
        var pc , key , channel
        pc = @.peerConnections[socketId]

        if !socketId
            @.emit "data_channel_create_error",socketId,new Error "attempt to create data channel without socket id"

        if !(pc instanceof PeerConnection)
            @.emit "data_channel_create_error",socketId,new Error "attempt to create data channel without peerConnection"

        try
            channel = pc.createDataChannel(label)
            console.log "————createDataChannel函数内部----"

        catch error
            @.emit "data_channel_create_error",socketId,error

        return @.addDataChannel socketId,channel

    # 为Data Channel绑定相应地事件回调函数
    chatrtc::addDataChannel = (socketId,channel) ->
        thats = @

        channel.onopen = !->
            thats.emit "data_channel_opened",channel,socketId

        channel.onclose = !->
            delete thats.dataChannels[socketId]
            thats.emit "data_channel_closed",channel,socketId

        channel.onmessage = (message)!->
            json = JSON.parse message.data
            if json.type == '__file'
                thats.parseFilePacket json,socketId
            else
                thats.emit "data_channel_message",channel,socketId

        channel.onerror = (error)!->
            thats.emit "data_channel_error",channel,socketId,error

        @.dataChannels[socketId] = channel
        return channel


    /******************************************************
    *
    *文件传输部分
    *
    *******************************************************/

    # 
    # 公有部分
    # 

    # 解析Data Channel上的文件类型包，来确定信令类型
    chatrtc::parseFilePacket = (json,socketId)!->
        signal = json.signal
        thats = @

        if signal == 'ask'
            thats.reveiveFileAsk json.socketId,json.name,json.size,socketId
        else if signal == 'accept'
            thats.receiveFileAccept json.sendId,socketId
        else if signal == 'refuse'
            thats.receiveFileRefuse json.sendId,socketId
        else if signal == 'chunk'
            thats.receiveFileChunk json.data,json.sendId,socketId,json.last,json.percent
        else if signal == 'close'
            thats.receiveFileClose socketId
        else
            # do something


    # 
    # 发送者部分
    # 

    # 通过Data Channel向房间所有其他用户广播文件
    chatrtc::shareFile = (dom)!->
        var socketId
        thats = @ 
        for socketId of thats.dataChannels
            thats.sendFile dom,socketId

    # 向某一个用户发送文件
    chatrtc::sendFile = (dom,socketId)->
        var file , reader , fileToSend , sendId
        thats = @

        if typeof(dom) == 'string'
            dom = document.getElementById dom
        
        if !dom 
            thats.emit "send_file_error",new Error "Can not find dom while sending file" ,socketId
            return
        if !dom.files || !dom.files[0]
            thats.emit "send_file_error",new Error "No file need to be sended",socketId
            return
        
        file = dom.files[0]
        thats.fileChannels[socketId] = thats.fileChannels[socketId] || {}
        sendId = thats.getRandomString
        fileToSend = 
            * file : file
              state : 'ask'
        thats.fileChannels[socketId][sendId] = fileToSend
        thats.sendAsk socketId,sendId,fileToSend
        thats.emit "send_file",sendId,socketId,file

    chatrtc::sendFileChunks = ->
        var socketId , sendId
        nextTick = false
        thats = @
        for socketId of thats.fileChannels
            for sendId of thats.fileChannels[socketId]
                if thats.fileChannels[socketId][sendId].state == 'send'
                    nextTick = true
                    thats.sendFileChunk socketId,sendId
        if nextTick
            setTimeout ->
                thats.sendFileChunks
            ,10

    # 发送某个文件的碎片
    chatrtc::sendFileChunk = (socketId,sendId)->
        var channel
        thats = @
        fileToSend = thats.fileChannels[socketId][sendId]
        packet = 
            * type : "__file"
              signal : "chunk"
              sendId : sendId

        fileToSend.sendedPakcets++
        fileToSend.packetsToSend--

        if fileToSend.fileData.length > packetSize
            packet.last = false
            packet.data = fileToSend.fileData.slice 0 , packetSize
            packet.percent = fileToSend.sendedPakcets / fileToSend.allPackets * 100
            thats.emit "send_file_chunk" , sendId , socketId , fileToSend.sendedPakcets / fileToSend.allPackets * 100 , fileToSend.file
        else
            packet.data = fileToSend.fileData
            packet.last = true
            fileToSend.state = "end"
            thats.emit "send_file",sendId,socketId,fileToSend.file
            thats.cleanSendFile sendId,socketId

        channel = thats.dataChannels[socketId]

        if !channel
            thats.emit "send_file_error",new Error "Channel has been destoried",socketId,sendId,fileToSend.file
            return

        channel.send JSON.stringify packet
        fileToSend.fileData = fileToSend.fileData.slice packet.data.length

    # 发送文件请求后若对方同意接受，开始传输
    chatrtc::receiveFileAccept = (sendId,socketId)!->
        var fileToSend , reader
        thats = @
        initSending = (event,text)!->
            fileToSend.state = "send"
            fileToSend.fileData = event.target.result
            fileToSend.sendedPakcets = 0
            fileToSend.packetsToSend = fileToSend.allPackets = parseInt fileToSend.fileData.length / packetSize , 10
            thats.sendFileChunks

        fileToSend = thats.fileChannels[socketId][sendId]
        reader = new window.FileReader fileToSend.file
        reader.readAsDataURL fileToSend.file
        reader.onload = initSending
        thats.emit "send_file_accepted",sendId,socketId,thats.fileChannels[socketId][sendId].file

    # 发送文件请求后若对方拒绝接受，则清除本地文件信息
    chatrtc::receiveFileRefuse = (sendId,socketId)!->
        thats = @
        thats.fileChannels[socketId][sendId].state = "refused"
        thats.emit "send_file_refused",sendId,socketId,thats.fileChannels[socketId][sendId].file
        thats.cleanSendFile sendId,socketId

    # 清除发送文件缓存
    chatrtc::cleanSendFile = (sendId,socketId)!->
        thats = @
        delete thats.fileChannels[socketId][sendId]

    # 发送文件请求
    chatrtc::sendAsk = (socketId,sendId,fileToSend)!->
        var packet
        thats = @
        channel = thats.dataChannels[socketId]

        if !channel
            thats.emit "send_file_error",new Error "Channel has been closed" , socketId , sendId , fileToSend.file

        packet = 
            * name : fileToSend.file.name
              size : fileToSend.file.size
              sendId : sendId
              type : "__file"
              signal : "ask"

        channel.send JSON.stringify packet

    # 获得随机字符串来生成文件发送ID
    chatrtc::getRandomString = !->
        # return (Math.random * new Date().getTime()).toString(36).toUpperCase().replace(/\.g,'-')

    # 
    # 接收者部分
    # 

    # 接收到文件碎片
    chatrtc::receiveFileChunk = (data,sendId,socketId,last,percent)!->
        thats = @
        fileInfo = thats.receiveFiles[sendId]

        if !fileInfo.data
            fileInfo.state = "receive"
            fileInfo.data = ""
        
        fileInfo.data = fileInfo.data || ""
        fileInfo.data += data
        if(last)
            fileInfo.state = "end"
            thats.getTransferedFile sendId
        else
            thats.emit "receive_file_chunk",sendId,socketId,fileInfo.name,percent

    # 接收到所有文件碎片后将其组合成一个完整的文件并自动下载
    chatrtc::getTransferedFile = (sendId)!->
        fileInfo = thats.receiveFiles[sendId]
        hyperlink = document.createElement 'a'
        mouseEvent = new MouseEvent 'click',{
            view:window,
            bubbles:true,
            cancelable:true
        }

        thats = @

        hyperlink.href = fileInfo.data
        hyperlink.target = '_blank'
        hyperlink.download = fileInfo.name || dataURL 

        hyperlink.dispatchEvent mouseEvent
        (window.URL || window.webkitURL).revokeObjectURL hyperlink.href
        thats.emit "receive_file",sendId,fileInfo.socketId,fileInfo.name
        thats.cleanReceiveFile sendId

    # 接收到发送文件请求后记录文件信息
    chatrtc::receiveFileAsk = (sendId,fileName,fileSize,socketId)!->
        thats = @
        thats.receiveFiles[sendId] = 
            * socketId : socketId
              state : "ask"
              name : fileName
              size : fileSize
        thats.emit "receive_file_ask",sendId,socketId,fileName,fileSize

    # 发送同意接收文件信令
    chatrtc::sendFileAccept = (sendId)!->
        var packet
        thats = @
        fileInfo = thats.receiveFiles[sendId]
        channel = thats.dataChannels[fileInfo.socketId]

        if !channel
            thats.emit "receive_file_error",new Error "Channel has been destoried",sendId,socketId

        packet = 
            * type : "__file"
              signal : "accept"
              sendId : sendId

        channel.send JSON.stringify packet

    # 发送拒绝接收文件信令
    chatrtc::sendFileRefuse = (sendId)!->
        var packet
        thats = @
        fileInfo = thats.receiveFiles[sendId]
        channel = thats.dataChannels[fileInfo.socketId]

        if !channel
            thats.emit "receive_file_error",new Error "Channel has been destoried",sendId,socketId

        packet = 
            * type : "__file"
            signal : "refuse"
            sendId : sendId

        channel.send JSON.stringify packet
        thats.cleanReceiveFile sendId

    # 清除接收文件缓存
    chatrtc::cleanReceiveFile = (sendId)!->
        thats = @
        delete thats.receiveFiles[sendId]

    new chatrtc()
