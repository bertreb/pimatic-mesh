module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  util = require 'util'
  commons = require('pimatic-plugin-commons')(env)

  # Device class representing an UniPi relay switch
  class PimaticRemoteSwitch extends env.devices.PowerSwitch

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
      env.logger.info "lastState switch: " + JSON.stringify(lastState)
      @remotePimatic = @config.remotePimatic
      @remoteDevice = @config.remoteDeviceId
      @_state = lastState.state.value

      super()

      @plugin.remotes[@remotePimatic].on @remoteDevice, (event) =>
        @emit event.attributeName, event.value

    getState: () ->
      return Promise.resolve @_state

    changeStateTo: (newState) ->
      @_base.debug 'state change requested to:', newState

      @plugin.remotes[@remotePimatic].action @remoteDevice, "changeStateTo", {
        state: newState
      }

    destroy: () =>
      super()
