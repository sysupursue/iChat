click-login-button = !->
  username = $ '.login-container input[name=username]' .val!
  password = $ '.login-container input[name=password]' .val!
  remember = $ '.login-container input[name=remember]' .val!

  console.log "login click"
  $.ajax do 
    type:'post'
    url:'/login'
    data:{username,password,remember}

    #成功服务器返回的数据，并跳转到对应用户的聊天界面
    success:(data)!->
        console.log "Data:" + data

    error:(jqXHR,text-status)!->
        console.log "登录数据发送失败"

$ !->
    $ '#login-button' .click click-login-button
    $ '#register-button' .click !-> 
        location.href = '/register'
        console.log "login click"




