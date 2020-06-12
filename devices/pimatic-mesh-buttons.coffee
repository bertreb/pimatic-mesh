module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  util = require 'util'
  commons = require('pimatic-plugin-commons')(env)

  class PimaticMeshButtons extends env.devices.Device

    attributes:
      button:
        description: "The last pressed button"
        type: "string"

    actions:
      buttonPressed:
        params:
          buttonId:
            type: "string"
        description: "Press a button"

    template: "buttons"

    _lastPressedButton: null

    constructor: (@config, @plugin, lastState) ->
      @id = @config.id
      @name = @config.name

      @debug = @plugin.config.debug ? @plugin.config.__proto__.debug
      @_base = commons.base @, @config.class
      console.log "@debug", @debug
      @_base.debug "initializing:", util.inspect(@config) if @debug
      @remotePimatic = @config.remotePimatic
      @remoteDevice = @config.remoteDeviceId
      @_lastPressedButton = lastState?.button?.value ? null
      env.logger.info "tot hier " + @config.id
      for button in @config.buttons
       @_button = button if button.id is @_lastPressedButton

      super()

      @plugin.remotes[@remotePimatic].on @remoteDevice, (event) =>
        @emit event.attributeName, event.value

    getButton: () ->
      return Promise.resolve @_lastPressedButton

    buttonPressed: (buttonId) ->
      @_base.debug 'button pressed:', buttonId

      @plugin.remotes[@remotePimatic].action @remoteDevice, "buttonPressed", {
        buttonId: buttonId
      }

    destroy: () =>
      super()
