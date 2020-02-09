module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  util = require 'util'
  commons = require('pimatic-plugin-commons')(env)

  class PimaticMeshTemperature extends env.devices.TemperatureSensor

    attributes:
      temperature:
        description: "The measured temperature"
        type: "number"
        unit: '°C'
        acronym: 'T'
      humidity:
        description: "The actual degree of Humidity"
        type: "number"
        unit: '%'
        acronym: 'H'
    actions:
      changeTemperatureTo:
        params:
          temperature:
            type: "number"
      changeHumidityTo:
        params:
          humidity:
            type: "number"

    constructor: (@config, @plugin, lastState) ->
      @debug = @plugin.config.debug ? @plugin.config.__proto__.debug
      @_base = commons.base @, @config.class
      console.log "@debug", @debug
      @_base.debug "initializing:", util.inspect(@config) if @debug
      @id = @config.id
      @name = @config.name
      @remotePimatic = @config.remotePimatic
      @remoteDeviceId = @config.remoteDeviceId
      @_temperature = lastState?.temperature?.value or 0
      @_humidity = lastState?.humidity?.value or 0
      super()

      @plugin.remotes[@remotePimatic].on @remoteDeviceId, (event) =>
        env.logger.info "event: " + JSON.stringify(event)
        @emit event.attributeName, event.value

    getTemperature: () ->
      return Promise.resolve @_temperature

    changeTemperatureTo: (value) ->
      @_base.debug 'set temperature:', value

      @plugin.remotes[@remotePimatic].action @remoteDeviceId, "changeTemperatureTo", {
        temperature: value
      }

    getHumidity: () ->
      return Promise.resolve @_humidity

    changeHumidityTo: (value) ->
      @_base.debug 'set humidity:', value

      @plugin.remotes[@remotePimatic].action @remoteDeviceId, "changeHumidityTo", {
        temperature: value
      }

    destroy: () =>
      super()
