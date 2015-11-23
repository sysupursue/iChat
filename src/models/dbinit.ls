require! <[../../config mongoose]>

module.exports = !->
  url = 'mongodb://' + config.db.host + '/' + config.db.name

  mongoose.connect url

  db = mongoose.connection;
  db.on 'error', console.error.bind console, 'Connection connected fail:'
  db.once 'open', (callback)!-> console.log "Successfully Connect "+ config.db.name
