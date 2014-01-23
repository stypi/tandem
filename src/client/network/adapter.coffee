class TandemNetworkAdapter extends EventEmitter2
  @events:
    DISCONNECT   : 'adapter-disconnect'
    ERROR        : 'adapter-error'
    READY        : 'adapter-ready'
    RECONNECT    : 'adapter-reconnect'
    RECONNECTING : 'adapter-reconnecting'

  constructor: ->
    @ready = false
    @sendQueue = []
    # Descendant responsible for calling setReady()

  close: ->
    this.removeAllListeners()

  listen: (route, callback) ->
    console.warn "Should be overwritten by descendant"
    return this

  send: (route, packet, callback, clientCallbacks, priority = false) ->
    if @ready
      this._send(route, packet, callback, clientCallbacks, priority)
    else
      if priority
        @sendQueue.unshift([route, packet, callback, clientCallbacks])
      else
        @sendQueue.push([route, packet, callback, clientCallbacks])

  setReady: ->
    this.emit(TandemNetworkAdapter.events.READY)
    async.until( =>
      return @sendQueue.length == 0
    , (callback) =>
      elem = @sendQueue.shift()
      [route, packet, sendCallback, clientCallbacks] = elem
      this._send(route, packet, (args...) =>
        sendCallback.apply(this, args) if sendCallback?
        callback()
      , clientCallbacks)
    , (err) =>
      @ready = true
    )

  _send: (route, packet, callback, clientCallbacks) ->
    console.warn "Should be overwritten by descendant"


module.exports = TandemNetworkAdapter
