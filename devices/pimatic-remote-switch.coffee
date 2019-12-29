module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  util = require 'util'
  commons = require('pimatic-plugin-commons')(env)

  class PimaticRemoteSwitch extends env.devices.PowerSwitch

    constructor: (@config, @plugin, lastState) ->
      @debug = @plugin.config.debug ? @plugin.config.__proto__.debug
      @_base = commons.base @, @config.class
      console.log "@debug", @debug
      @_base.debug "initializing:", util.inspect(@config) if @debug
      @id = @config.id
      @name = @config.name
      @remotePimatic = @config.remotePimatic
      @remoteDevice = @config.remoteDeviceId
      @_state = lastState?.state?.value or off

      super()

      @plugin.remotes[@remotePimatic].on @remoteDevice, (event) =>
        @emit event.attributeName, event.value

    getState: () ->
      return Promise.resolve @_state

    changeStateTo: (newState) ->
      @_base.debug 'state change to:', newState

      @plugin.remotes[@remotePimatic].action @remoteDevice, "changeStateTo", {
        state: newState
      }

    destroy: () =>
      super()
