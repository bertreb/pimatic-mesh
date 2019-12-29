module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  util = require 'util'
  commons = require('pimatic-plugin-commons')(env)

  class PimaticRemoteTemperature extends env.devices.TemperatureSensor

    constructor: (@config, @plugin, lastState) ->
      @debug = @plugin.config.debug ? @plugin.config.__proto__.debug
      @_base = commons.base @, @config.class
      console.log "@debug", @debug
      @_base.debug "initializing:", util.inspect(@config) if @debug
      @id = @config.id
      @name = @config.name
      @remotePimatic = @config.remotePimatic
      @remoteDevice = @config.remoteDeviceId
      @_temperature = lastState?.temperature?.value or 0
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
