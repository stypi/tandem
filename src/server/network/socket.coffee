_             = require('underscore')._
async         = require('async')
socketio      = require('socket.io')
EventEmitter  = require('events').EventEmitter
TandemAdapter = require('./adapter')
TandemEmitter = require('../emitter')
TandemFile    = require('../file')


_authenticate = (client, packet, callback) ->
  async.waterfall([
    (callback) =>
      @storage.authorize(packet, callback)
    (callback) =>
      this.emit(TandemAdapter.events.CONNECT, client.id, packet.fileId, packet.userId, callback)
  ], (err) =>
    err = err.message if err? and _.isObject(err)   # Filter error info passed to front end client
    callback({ error: err })
  )


class TandemSocket extends TandemAdapter
  @DEFAULTS:
    'browser client': false
    'log level': 1
    'transports': ['websocket', 'xhr-polling']

  constructor: (httpServer, @storage, options = {}) ->
    @settings = _.defaults(_.pick(options, _.keys(TandemSocket.DEFAULTS)), TandemSocket.DEFAULTS)
    @sockets = {}
    @io = socketio.listen(httpServer, @settings)
    @io.configure('production', =>
      @io.enable('browser client minification')
      @io.enable('browser client etag')
    )
    @io.sockets.on('connection', (socket) =>
      @sockets[socket.id] = socket
      socket.on('auth', (packet, callback) =>
        _authenticate.call(this, socket, packet, callback)
      )
    )

  addClient: (sessionId, userId, file) ->
    this.broadcast(sessionId, TandemFile.routes.JOIN, userId)
    file.users[userId] ?= 0
    file.users[userId] += 1
    socket = @sockets[sessionId]
    _.each(TandemFile.routes, (route, name) ->
      socket.removeAllListeners(route)
    )
    socket.on('disconnect', =>
      this.removeClient(sessionId, userId, file)
    )
    super

  removeClient: (sessionId, userId, file) ->
    this.broadcast(sessionId, TandemFile.routes.LEAVE, userId) if userId?
    this.leave(sessionId, file.id)
    file.users[userId] -= 1 if file.users[userId]?

  broadcast: (sessionId, fileId, route, packet) ->
    socket = @sockets[sessionId]
    socket.broadcast.to(fileId).emit(route, packet)

  join: (sessionId, fileId) ->
    socket = @sockets[sessionId]
    socket.join(fileId)

  leave: (sessionId, fileId) ->
    socket = @sockets[sessionId]
    socket.leave(fileId)

  listen: (sessionId, route, callback) ->
    socket = @sockets[sessionId]
    socket.on(route, callback)
    return this


module.exports = TandemSocket
