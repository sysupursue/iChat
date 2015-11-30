click-register-button = !->
  console.log "register-btn clicked."
  username = $ '.register-container input[name=username]' .val!
  email = $ '.register-container input[name=email]' .val!
  password = $ '.register-container input[name=password]' .val!
  repassword = $ '.register-container input[name=repassword]' .val!
  # username ='test'
  # email = 'test@qq.com'
  # password = '123456'
  # repassword = '123456'

  $.ajax {
    type: 'POST'
    url: '/register'
    data: {username,email,password,repassword}
  }
  .done (data)!->
    if data.success then location.href = '/login' 
    else console.log "数据发送失败"
  .fail (jqXHR,text-status)!-> console.log "Error:"+text-status
  
$ !->
  $ '#register-button' .click click-register-button