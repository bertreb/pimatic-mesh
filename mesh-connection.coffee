# Class PimaticMeshConnection
module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  events = require 'events'
  url = require 'url'
  io = require 'socket.io-client'

  class PimaticMeshConnection extends events.EventEmitter

    constructor: (@config, plugin) ->
      @debug = plugin.config.debug ? plugin.config.__proto__.debug
      @base = commons.base @, 'PimaticMeshConnection'
      @baseUrl = url.parse @config.url
      @username = encodeURIComponent @config.username
      @password = encodeURIComponent @config.password
      @pimaticId = @config.id
      @actionCounter = 0
      @actionResultCallbacks = {}
      @attributeChangeCallbacks = {}
      @remoteDevices = {}
      @connected = false
      @connectError = "connection closed"

      @socket = io url.resolve @baseUrl, '/?username=' + @username + '&password=' + @password, {
        reconnection: true,
        reconnectionDelay: 5000,
        reconnectionDelayMax: 10000,
        timeout: 20000,
        forceNew: true
      }
      super()

      @socket.on 'connect', () =>
        @base.debug "connected"
        @connected = true
        @connectError = null

      @socket.on 'reconnect', (noAttempts) =>
        @base.debug "reconnected"
        @connected = true
        @connectError = null

      @socket.on 'disconnect', () =>
        @base.debug 'disconnected'
        @connected = false
        @connectError = "connection closed" if @connectError?

      @socket.on 'connect_error', (error) =>
        @base.error "connection attempt to remote peer failed" #, error
        @connected = false
        @connectError = error

      @socket.on 'error', (error) =>
        @base.error "connection to remote peer failed" # , error
        @connected = false
        @connectError = error

      @socket.on 'devices', (devices) =>
        @base.debug "remote devices received"
        @remoteDevices = devices

      @socket.on 'hello', (user) =>
        @base.debug 'hello', user
        if user.permissions? and not user.permissions.controlDevices
          @base.error "Remote user entity #{user.username} has insufficient privileges to control devices"
 
      
      @socket.on 'deviceAttributeChanged', (attrEvent) =>
        #env.logger.info "deviceATtrChanged: " + JSON.stringify(attrEvent,null,2)
        @emit attrEvent.deviceId, attrEvent

      @socket.on 'callResult', (result) =>
        if @actionResultCallbacks.hasOwnProperty result.id
          @actionResultCallbacks[result.id].call @, result
          delete @actionResultCallbacks[result.id]

    getDevices: () =>
      return @remoteDevices

    _getActionId: () ->
      @actionCounter = 0 if @actionCounter > 100000
      return @actionCounter++

    action: (deviceId, actionName, params) ->
      @base.debug "calling action #{actionName} on device #{deviceId}"
      new Promise (resolve, reject) =>
        if @connected
          id = '' + @_getActionId()
          actionParams = _.assign {}, params || {},
            deviceId: deviceId
            actionName: actionName
          @socket.emit 'call', {
            id: id,
            action: 'callDeviceAction',
            params: actionParams
          }
          @actionResultCallbacks[id] = (result) =>
            @base.debug "action #{actionName} on device #{deviceId} result", result
            if result.success
              resolve result.result
            else
              reject result.error
        else
            reject "Connection to remote peer failed: #{@connectError}"

    destroy: () =>
      @socket.close()
      @socket.removeAllListeners()
      super()

