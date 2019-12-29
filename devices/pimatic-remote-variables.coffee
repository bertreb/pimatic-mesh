module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  util = require 'util'
  commons = require('pimatic-plugin-commons')(env)

  class PimaticRemoteVariables extends env.devices.Device

    constructor: (@config, @plugin, lastState) ->
      @id = @config.id
      @name = @config.name
      @debug = @plugin.config.debug ? @plugin.config.__proto__.debug
      @_base = commons.base @, @config.class
      console.log "@debug", @debug
      @_base.debug "initializing:", util.inspect(@config) if @debug
      @remotePimatic = @config.remotePimatic
      @remoteDevice = @config.remoteDeviceId
      @attributes = {}
      @values = {}

      for variable in @config.variables
        do (variable) =>
          name = variable.name
          info = null

          @values[variable.name] = lastState[variable.name]?.value or 0

          if @attributes[name]?
            throw new Error(
              "Two variables with the same name in VariablesDevice config \"#{name}\""
            )

          @attributes[name] = {
            description: name
            label: (if variable.label? then variable.label else "$#{name}")
            type: variable.type or "string"
          }

          if variable.unit? and variable.unit.length > 0
            @attributes[name].unit = variable.unit

          if variable.discrete?
            @attributes[name].discrete = variable.discrete

          if variable.acronym?
            @attributes[name].acronym = variable.acronym

          @_createGetter(variable.name, =>
            return @values[variable.name]
            )

          super()
          @plugin.remotes[@remotePimatic].on variable.remoteDeviceId, (_event) =>
            variable = @findVariable(_event.deviceId, _event.attributeName)
            if variable?
              @values[variable.name] = _event.value
              @emit variable.name, @values[variable.name]

    findVariable: (deviceName, attributeName) =>
      _.find(@config.variables, (v) => deviceName is v.remoteDeviceId and attributeName is v.remoteAttributeId)

    destroy: () =>
      super()
