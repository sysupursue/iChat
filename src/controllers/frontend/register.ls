click-register-button = !->
  username = $ '.register-container input[name=username]' .val!
  email = $ '.register-container input[name=email]' .val!
  password = $ '.register-container input[name=password]' .val!
  repassword = $ '.register-container input[name=repassword]' .val!

  $.ajax do
    type: 'POST'
    url: '/register'
    data: {username,email,password,repassword}
  
    success:(data)!->
        if data.success then alter "注册数据发送成功！"
    error:(jqXHR, text-status)!-> 
        console.log '数据发送失败'

    $ !->
      $ '#register-button' .click click-register-button