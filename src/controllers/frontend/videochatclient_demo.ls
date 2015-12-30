# local-media = $ '.local-media'
# remote-media = $ '.remote-media'
# self-view = documet.getElementById 'local-media'
# remote-view = documet.getElementById 'remote-media'
# video-chat-btn = $ '.video-chat-btn'

# navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia;
# PeerConnection = window.PeerConnection || window.webkitPeerConnection00 ||window.webkitRTCPeerConnection || window.mozRTCPeerConnection
# nativeRTCIceCandidate = window.mozRTCIceCandidate || window.RTCIceCandidate
# nativeRTCSessionDescription = window.mozRTCSessionDescription || window.RTCSessionDescription

# signalingChannel = new SignalingChannel

# configuration = 
#     * "iceServer":
#         * "url":"stun服务器"
#         * "url":
#             * "turn服务器1"
#               "turn服务器2"
#           "username":"user"
#           "credential":"mypassword"
#           "credentialType":"password"
# pc

# start = !->
#     pc = new PeerConnection configuration

#     # send any ice candidate to the other peer
#     pc.onicecandidate = (evt)->
#         if evt.candidate
#             signalingChannel.send JSON.stringify {"candidate":evt.candidate}

#     # let the "negotiationneeded" event trigger offer generation
#     pc.onnegotiationneeded = ->
#         pc.createOffer().then (offer)->
#             return pc.setLocalDescription offer
#         .then ->
#             signalingChannel.send JSON.stringify {"desc":pc.localDescription}
#         .catch logError

#     # once remote video trace arrives , show it in the remote video element
#     pc.ontrack = (evt)->
#         if evt.track.kind == "video"
#             remoteView.srcObject = evt.streams[0]

#     # get a local stream , show it in a self-view and add it to be sent
#     navigator.getUserMedia constrains,(stream)->
#             if window.URL 
#                 self-view.src = window.URL.createObjectURL stream
#             else
#                 self-view.src = stream
#             self-view.onloadedmetadata = (e)->
#             console.log("Label: " + stream.label);
#             console.log("AudioTracks" , stream.getAudioTracks());
#             console.log("VideoTracks" , stream.getVideoTracks());  
#         ,(error)->
#             console.log "获取本地视频失败"+error

# signalingChannel.onmessage = (evt)->
#     if !pc
#         start!

#     message = JSON.parse evt.data
#     if message.desc 
#         # if we get an offer , we need to replay with an answer
#         if desc.type == offer 
#             pc.setRemoteDescription desc .then ->
#                 return pc.createAnswer


# /********************************************************
# *
# *针对本地视频流的处理部分
# *
# *********************************************************/
# constrains = {
#     video:true,
#     audio:false
# }

# localSuccess = (localMediaStream)!->
#     window.localMediaStream = localMediaStream
#     if window.URL 
#         selfview.src = window.URL.createObjectURL localMediaStream
#     else
#         selfview.src = localMediaStream

#     selfview.onloadedmetadata = (e)->
#         console.log("Label: " + localMediaStream.label);
#         console.log("AudioTracks" , localMediaStream.getAudioTracks());
#         console.log("VideoTracks" , localMediaStream.getVideoTracks());        

# localFailed = (error)!->
#     console.log "获取本地视频失败"+error

# # 点击视频聊天键，建立点对点的视频连接
# click-video-chat-btn = !->
#     console.log "视频聊天按钮点击"
#     console.log "本地视频源："+local-media.src
#     # 获取本地视频，并把本地视频挂到指定的videoy元素上
#     navigator.getUserMedia constrains,localSuccess ,localFailed


# $ ->
#     video-chat-btn .click click-video-chat-btn

# /********************************************************
# *
# *针对远程视频流的处理部分
# *
# *********************************************************/
