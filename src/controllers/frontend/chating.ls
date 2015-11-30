chat-content = $ '.chat-content'

edit-area = $ '.edit-area'
message-send-btn = $ '.message-send-btn'

socket = io();

message-send-btn.on 'click',->
    console.log "message-send-btn clicked."
    socket.emit('new message',edit-area.val())
    edit-area.val(' ')


# 一条信息
other-message-item = $ '<div>',{
    'class':'other-message-item'
}

message-item = $ '<div>',{
    'class':'message-item'
}

message-box = $ '<div>',{
    'class':'message-box'
}

socket.on 'new message',(msg)->
    chat-content.append other-message-item .append message-item .append message-box .append ($('pre').text(msg))

socket.on 'online',(userdata)->
