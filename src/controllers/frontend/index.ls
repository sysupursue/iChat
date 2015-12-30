videos = document.getElementById "videos"
sendBtn = document.getElementById "sendBtn"
msgs = document.getElementById "msgs"
sendFileBtn = document.getElementById "sendFileBtn"
files = document.getElementById "files"

rtc = ChatRTC()

sendBtn.onclick = (event)!->
    msgIpt = document.getElementById "msgIpt"
    msg = msgIpt.value()
    p = document.createElement "p"
    p.innerText = "me:" + msg

    rtc.broadcast msg
    msgIpt.value = ""
    msgs.appendChild p

sendFileBtn.onclick = (event)!->
    rtc.shareFile "fileIpt"


# 成功创建WebSocket连接
rtc.on "connected",(socket)!->
    console.log "connected事件触发"
    # 创建本地视频流
    rtc.createStream({
        "video" : true
        # "audio" : true
    })

# 创建本地视频流成功
rtc.on "stream_created",(stream)!->
    document.getElementById('me').src = URL.createObjectURL(stream)
    document.getElementById('me').play()

# 创建本地视频流失败
rtc.on "stream_create_error",!->
    alter 'create stream failed!'

# 接收到其他用户的视频流
rtc.on "pc_add_stream",(stream,socketId)!->
    console.log "pc_add_stream"
    newvideo = document.createElement "video"
    id = "other-" + socketId
    newvideo.setAttribute "class","other"
    newvideo.setAttribute "autoplay","autoplay"
    newvideo.setAttribute "id",id
    videos.appendChild newvideo
    rtc.attachStream(stream,id)

# 删除其他用户
rtc.on "remove_peer",(socketId)!->
    video = document.getElementById "other-" + socketId
    if video
        video.parentNode.removeChild video


# 接收到文字消息
rtc.on "data_channel_message",(channel,socketId,message)!->
    p = document.createElement 'p'
    p.innerText = socketId + ": " + message
    msgs.appendChild p

# 连接WebSocket服务器
rtc.connect("ws:" + window.location.href.substring(window.location.protocol.length).split('#')[0], window.location.hash.slice(1))
console.log "arg1:" + ("ws:" + window.location.href.substring(window.location.protocol.length).split('#')[0]) + "arg2:" + (window.location.hash.slice(1))
