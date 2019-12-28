# Class PimaticRemoteConnection
module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  events = require 'events'
  url = require 'url'
  io = require 'socket.io-client'

  class PimaticMeshConnections extends events.EventEmitter

    constructor: (@config, plugin) ->
      @debug = plugin.config.debug ? plugin.config.__proto__.debug
      @base = commons.base @, 'PimaticMeshConnections'

      @remotes = {}
      for remoteConfig in @config.remotes
        remote =
          id: remoteConfig.id
          baseUrl: remoteConfig.url
          username: encodeURIComponent remoteConfig.username
          password: encodeURIComponent remoteConfig.password
          socket: null
          actionCounter: 0
          actionResultCallbacks: {}
          attributeChangeCallbacks: {}
          connected: false
          connectError: "connection closed"
          base: commons.base @, 'PimaticMeshConnections'

        Connections = new Promise( (resolve, reject) =>
          socket = io url.resolve remote.baseUrl, '/?username=' + remote.username + '&password=' + remote.password, {
            reconnection: true,
            reconnectionDelay: 1000,
            reconnectionDelayMax: 3000,
            timeout: 20000,
            forceNew: true
          }

          socket.on 'connect', () =>
            env.logger.info "connected to #{socket.id}"
            remote.base.debug "connected"
            remote.connected = true
            remote.connectError = null
            resolve()

          socket.on 'reconnect', (noAttempts) =>
            remote.base.debug "reconnected"
            remote.connected = true
            remote.connectError = null

          socket.on 'disconnect', () =>
            remote.base.debug 'disconnected'
            remote.connected = false
            remote.connectError = "connection closed" if remote.connectError?

          socket.on 'connect_error', (error) =>
            remote.base.error "connection attempt to remote peer failed:", error
            remote.connected = false
            remote.connectError = error

          socket.on 'error', (error) =>
            remote.base.error "connection to remote peer failed:", error
            remote.connected = false
            remote.connectError = error

          socket.on 'hello', (user) =>
            remote.base.debug 'hello', user
            if user.permissions? and not user.permissions.controlDevices
              remote.base.error "Remote user entity #{user.username} has insufficient privileges to control devices"

          socket.on 'deviceAttributeChanged', (attrEvent) =>
            #env.logger.info "deviceATtrChanged: " + JSON.stringify(attrEvent,null,2)
            @emit attrEvent.deviceId, attrEvent

          socket.on 'callResult', (result) =>
            if remote.actionResultCallbacks.hasOwnProperty result.id
              remote.actionResultCallbacks[result.id].call @, result
              delete remote.actionResultCallbacks[result.id]

          remote.socket = socket
          @remotes[remoteConfig.id] = remote
        )

      super()

    _getActionId: (pimaticId) ->
      @remotes[pimaticId].actionCounter = 0 if @remotes[pimaticId].actionCounter > 100000
      return @remotes[pimaticId].actionCounter++

    action: (pimaticId, deviceId, actionName, params) ->
      @remotes[pimaticId].base.debug "calling action #{actionName} on device #{deviceId}"
      new Promise (resolve, reject) =>
        if @remotes[pimaticId].connected
          id = '' + @_getActionId(pimaticId)
          env.logger.info "id: " + id
          actionParams = _.assign {}, params || {},
            deviceId: deviceId
            actionName: actionName
          @remotes[pimaticId].socket.emit 'call', {
            id: id,
            action: 'callDeviceAction',
            params: actionParams
          }
          @remotes[pimaticId].actionResultCallbacks[id] = (result) =>
            @remotes[pimaticId].base.debug "action #{actionName} on device #{deviceId} result", result
            if result.success
              resolve result.result
            else
              reject result.error
        else
            reject "Connection to remote peer failed: #{@remotes[pimaticId].connectError}"
