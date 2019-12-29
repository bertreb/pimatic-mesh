module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  util = require 'util'
  commons = require('pimatic-plugin-commons')(env)

  class PimaticRemoteDimmer extends env.devices.DimmerActuator

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
      @_dimlevel = lastState?.dimlevel?.value or 0

      env.logger.info "@mesh: " + @mesh
      super()

      @plugin.remotes[@remotePimatic].on @remoteDevice, (event) =>
        @emit event.attributeName, event.value

    getDimlevel: () ->
      return Promise.resolve @_dimlevel

    getState: () ->
      return Promise.resolve @_state

    changeDimlevelTo: (level) ->
      @_base.debug 'set dimlevel:', level
      @_setDimlevel(level)

    changeStateTo: (state) ->
      if state then @turnOn() else @turnOff()
      @_base.debug 'set state:', state

    turnOn: () ->
      @_setDimlevel(100)

    turnOff: () ->
      @_setDimlevel(0)

    toggle:() ->
      state = !@getState()
      @changeStateTo(state)

    _setDimlevel: (level) =>
      @_dimlevel = level
      if level > 0 then @_state = 1 else @_state = 0
      @plugin.remotes[@remotePimatic].action @remoteDevice, "changeDimlevelTo", {
        dimlevel: level
      }

    destroy: () =>
      super()
