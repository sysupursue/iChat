var db = {
    host: '127.0.0.1',
    port: '27017',
    name: 'ecch'
}

//如果用1024以下的端口，需要管理员权限
var server = {
    host: 3000
}


module.exports = {
    db: db,
    server: server
}