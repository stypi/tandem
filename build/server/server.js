(function() {
  var EventEmitter, TandemEmitter, TandemFileManager, TandemMemoryCache, TandemNetworkAdapter, TandemServer, TandemSocket, TandemStorage, _,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  _ = require('lodash');

  EventEmitter = require('events').EventEmitter;

  TandemNetworkAdapter = require('./network/adapter');

  TandemEmitter = require('./emitter');

  TandemFileManager = require('./file-manager');

  TandemMemoryCache = require('./cache/memory');

  TandemSocket = require('./network/socket');

  TandemStorage = require('./storage');

  TandemServer = (function(_super) {
    __extends(TandemServer, _super);

    TandemServer.events = {
      ERROR: 'tandem-error'
    };

    TandemServer.routes = TandemNetworkAdapter.routes;

    TandemServer.DEFAULTS = {
      cache: TandemMemoryCache,
      network: TandemSocket,
      storage: TandemStorage
    };

    function TandemServer(server, options) {
      if (options == null) {
        options = {};
      }
      this.settings = _.defaults(options, TandemServer.DEFAULTS);
      this.storage = _.isFunction(this.settings.storage) ? new this.settings.storage : this.settings.storage;
      this.fileManager = new TandemFileManager(this.storage, this.settings);
      if (this.settings.network === 'base') {
        this.settings.network = TandemNetworkAdapter;
      }
      this.network = _.isFunction(this.settings.network) ? new this.settings.network(server, this.fileManager, this.storage, this.settings) : this.settings.network;
      TandemEmitter.on(TandemEmitter.events.ERROR, (function(_this) {
        return function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return _this.emit.apply(_this, [TandemServer.events.ERROR].concat(__slice.call(args)));
        };
      })(this));
    }

    TandemServer.prototype.stop = function(callback) {
      return this.fileManager.stop(callback);
    };

    return TandemServer;

  })(EventEmitter);

  module.exports = TandemServer;

}).call(this);
