module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  util = require 'util'
  commons = require('pimatic-plugin-commons')(env)

  # Device class representing an UniPi relay switch
  class PimaticRemoteVariables extends env.devices.Device

    # Create a new PimaticRemoteVariable device
    # @param [Object] config    device configuration
    # @param [PimaticRemotePlugin] plugin   plugin instance
    # @param [Object] lastState state information stored in database
    constructor: (@config, @plugin, lastState) ->
      @id = @config.id
      @name = @config.name
      @debug = @plugin.config.debug ? @plugin.config.__proto__.debug
      @_base = commons.base @, @config.class
      console.log "@debug", @debug
      @_base.debug "initializing:", util.inspect(@config) if @debug
      #@mesh = @plugin.mesh.remotes[@config.remotePimatic].socket
      #env.logger.info "socketID: " + @mesh.id
      @attributes = {}
      @values = {}
      env.logger.info "lastState: " + JSON.stringify(lastState)

      for variable in @config.variables
        do (variable) =>
          name = variable.name
          info = null

          @values[variable.name] = lastState[variable.name].value

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
          @plugin.mesh.on variable.remoteDeviceId, (_event) =>
            #env.logger.info "var received: " + _event
            variable = @findVariable(_event.deviceId, _event.attributeName)
            if variable?
              @values[variable.name] = _event.value
              @emit variable.name, @values[variable.name]


    findVariable: (deviceName, attributeName) =>
      _.find(@config.variables, (v) => deviceName is v.remoteDeviceId and attributeName is v.remoteAttributeId)

    #getValue: () ->
    #  return Promise.resolve @_state

    ###
    changeStateTo: (newState) ->
      @_base.debug 'state change requested to:', newState

      @plugin.messenger.action @config.remoteId, "changeStateTo", {
        state: newState
      }
    ###

    destroy: () =>

      super()
