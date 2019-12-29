module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  util = require 'util'
  commons = require('pimatic-plugin-commons')(env)

  class PimaticRemotePresence extends env.devices.PresenceSensor

    constructor: (@config, @plugin, lastState) ->
      @debug = @plugin.config.debug ? @plugin.config.__proto__.debug
      @_base = commons.base @, @config.class
      console.log "@debug", @debug
      @_base.debug "initializing:", util.inspect(@config) if @debug
      @id = @config.id
      @name = @config.name
      @remotePimatic = @config.remotePimatic
      @remoteDevice = @config.remoteDeviceId
      #@mesh = @plugin.mesh.remotes[@config.remotePimatic].socket
      super()

      @plugin.remotes[@remotePimatic].on @remoteDeviceId, (event) =>
        @emit event.attributeName, event.value

    getPresence: () ->
      return Promise.resolve @_presence

    setPresence: (value) ->
      @_base.debug 'set presence:', value

      @plugin.remotes[@remotePimatic].action @remoteDeviceId, "presence", {
        state: value
      }

    destroy: () =>
      super()
