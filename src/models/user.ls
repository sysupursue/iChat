require! <[mongoose]>

# 用户schema
user-schema = mongoose.Schema {

  # 用户登录时所用的属性
  username        : String
  password        : String
  email           : type: String,  default: ''
  # isAdmin         : type: Boolean, default: false
}

module.exports = mongoose.model 'User', user-schema