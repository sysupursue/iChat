rtc = ChatRTC()

# 视频聊天
chat-video = $ '#chat-video'
video_mode = $ '.video-chat-wrapper'
text-mode = $ '.text-chat-wrapper'
# self-view = document.getElementById "self-view"

chat-video.on 'click',!->
    console.log "切换到视频模式"
    video_mode .add-class 'active' .remove-class 'hidden'
    text-mode .add-class 'hidden' 


/****************************************************
*
*文件传输部分
*
*****************************************************/


# 通用接收文件
rtc.on "send_file_accepted",(sendId,socketId,file)!->

# 拒绝接收文件
rtc.on "send_file_refused",(sendId,socketId,file)!->

# 请求发送文件
rtc.on "send_file",(sendId,socketId,file)!->

# 发送文件成功
rtc.on "sended_file",(sendId,socketId,file)!->

# 发送文件碎片
rtc.on "send_file_chunk",(sendId,socketId,percent,file)!->

# 接收文件碎片
rtc.on "receive_file_chunk",(sendId,socketId,file,percent)!->

# 接收文件
rtc.on "receive_file",(sendId,socketId,name)!->

# 发送文件时出现错误
rtc.on "send_file_error",(error)!->
    console.log error

# 接收文件时出现错误
rtc.on "receive_file_error",(error)!->
    console.log error

# 接收到文件发送请求
rtc.on "receive_file_ask",(sendId,socketId,fileName,fileSize)!->


/****************************************************
*
*远程Meida添加部分
*
*****************************************************/


# 成功创建WebSocket连接
rtc.on "connected",(socket)!->
    # 创建本地视频流
    rtc.createStream({
        "video" : true
        # "audio" : true
    })

# 创建本地视频流成功
rtc.on "stream_created",(stream)!->
    document.getElementById 'self-view' .src = URL.createObjectURL stream

# 创建本地视频流失败
rtc.on "stream_create_error",!->
    alter 'create stream failed!'

# 参与者列表
participantlist = $ '.participant-view-list'

# 接收到其他用户的视频流
rtc.on "pc_add_stream",(stream,socketId)!->
    console.log "chat.ls:添加远程流事件触发"
    newvideo = document.createElement "video"
    id = "other-" + socketId
    newvideo.setAttribute "class","participant-view-item"
    newvideo.setAttribute "autoplay","autoplay"
    newvideo.setAttribute "id",id
    participantlist.appendChild newvideo
    rtc.attachStream stream,id

# 删除其他用户
rtc.on "remove_peer",(socketId)!->
    video = document.getElementById "other-" + socketId
    if video
        video.parentNode.removeChild video


# 接收到文字消息
rtc.on "data_channel_message",(channel,socketId,message)!->


# 连接WebSocket服务器
rtc.connect("ws:" + window.location.href.substring(window.location.protocol.length).split('#')[0], window.location.hash.slice(1))
