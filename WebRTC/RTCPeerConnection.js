var peerConnection = window.RTCPeerConnection || window.mozRTCPeerConnection || window.webkitRTCPeerConnection || window.msRTCPeerConnection ;

var sessionDescription = window.RTCSessionSescription || window.mozRTCSessionDescription || window.webkitRTCSessionDescription || window.msRTCSessionDescription;

navigator.getUserMedia = navigator.getUserMedia || navigator.mozGetUserMeida || navigator.webkitGetUserMedia || navigator.msGetUserMeida

var pc = new RTCPeerConnection();

pc.onaddstream = function(obj){
    var vid = document.createElement("video");
    document.appendChild(vid);
    vid.srcObject = obj.stream;
}


// 关闭连接
function endCall(){
    var videos = document.getElementsByTadName("video");
    for(var i = 0 ; i < videos.length ; i++){
        videos[i].pasue();
    }

    pc.close();
}

// 初始化一个通话
// 1、从服务器获取朋友列表
// 2、用户选择一个朋友开始点对点连接
navigator.getUserMedia({audio:true,video:true},function(stream){
    // 添加本地流并不会触发onaddstream监听器中的回调函数
    pc.onaddstream({stream:stream});

    pc.addStream(stream);

    pc.createOffer(function(offer){
        pc.setLocalDescription(new RTCSessionSescription(offer),function(){
            // send the offer to a server to be forwarded to the friend you're calling.
        },error);
    },error);
});


// 应答通话
var offer = getOfferFromFrind();

navigator.getUserMedia({video:true},function(stream){
    pc.onaddstream({stream:stream});
    pc.addStream(stream);

    pc.setRemoteDescription(new RTCSessionSescription(offer),function(){
        pc.createAnswer(function(answer){
            pc.setLocalDescription(new RTCSessionSescription(answer),function(){
                 // send the answer to a server to be forwarded back to the caller (you)
             },error);
        },error);
    },error);
});










