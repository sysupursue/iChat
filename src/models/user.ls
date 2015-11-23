require! <[mongoose]>

# 用户schema
user-schema = mongoose.Schema {
  username        : String
  password        : String
  email           : type: String,  default: ''
  isAdmin         : type: Boolean, default: false
}

module.exports = mongoose.model 'User', user-schema