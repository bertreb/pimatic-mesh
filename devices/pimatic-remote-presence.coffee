module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  util = require 'util'
  commons = require('pimatic-plugin-commons')(env)

  # Device class representing an UniPi relay switch
  class PimaticRemotePresence extends env.devices.PresenceSensor

    # Create a new PimaticRemoteSwitch device
    # @param [Object] config    device configuration
    # @param [PimaticRemotePlugin] plugin   plugin instance
    # @param [Object] lastState state information stored in database
    constructor: (@config, @plugin, lastState) ->
      @debug = @plugin.config.debug ? @plugin.config.__proto__.debug
      @_base = commons.base @, @config.class
      console.log "@debug", @debug
      @_base.debug "initializing:", util.inspect(@config) if @debug
      @id = @config.id
      @name = @config.name
      @mesh = @plugin.mesh.remotes[@config.remotePimatic].socket
      super()

      @mesh.on @config.remoteDeviceId, (event) =>
        @emit event.attributeName, event.value

    getPresence: () ->
      return Promise.resolve @_presence

    setPresence: (value) ->
      @_base.debug 'set presence:', value

      @plugin.mesh.action @config.remoteDeviceId, "presence", {
        state: value
      }

    destroy: () =>
      super()