get-input-valid-message = (options)->
  username = options.username
  email = options.email
  password = options.password
  repassword = options.repassword
  can-password-be-empty = options.can-password-be-empty

  email-pattern = /^\w+@[a-zA-Z_]+?\.[a-zA-Z]{2,3}$/
  white-space-pattren = /\s/

  for op of options
    val=options[op]
    if val==''||val==null||white-space-pattren.test(options[op])
      return '值不能为空或者有空字符'

  if can-password-be-empty is undefined # 密码输入是否能留空
    can-password-be-empty = false

  # 用户名验证
  if username isnt undefined
    if username.length < 3
      return '用户名长度至少为3位'

    if username.length > 15
      return '用户名长度至多为15位'

    # if (username.match white-space-pattren) isnt null
    #   return error-message = '用户名中不能包含空白字符'

  # 邮箱验证
  if email isnt undefined
    unless email-pattern.test email
      return '邮箱格式不正确'

  # 密码验证
  if password isnt undefined
    if can-password-be-empty
      if password.length < 5 and password.length isnt 0
        return '密码长度至少为5位'
    else
      if password.length < 5
        return '密码长度至少为5位'

    if password.length > 16
      return  '密码长度至多为16位'

    if (password.match white-space-pattren) isnt null
      return  '密码中不能包含空白字符'

  # 密码确认
  if repassword isnt undefined
    if password isnt repassword
      return '两次输入的密码不一致'

module = module or undefined

if module and module.exports # 若在后端运行则输出该函数
  module.exports = {
    get-input-valid-message: get-input-valid-message
  }