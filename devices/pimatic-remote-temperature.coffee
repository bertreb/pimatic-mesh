module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  util = require 'util'
  commons = require('pimatic-plugin-commons')(env)

  # Device class representing an UniPi relay switch
  class PimaticRemoteTemperature extends env.devices.TemperatureSensor

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
      @remotePimatic = @config.remotePimatic
      @remoteDevice = @config.remoteDeviceId
      super()

      @plugin.remotes[@remotePimatic].on @remoteDeviceId, (event) =>
        @emit event.attributeName, event.value

    getTemperature: () ->
      return Promise.resolve @_temperature

    setTemperature: (value) ->
      @_base.debug 'set temperature:', value

      @plugin.remotes[@remotePimatic].action @remoteDeviceId, "temperature", {
        temperature: value
      }

    destroy: () =>
      super()

