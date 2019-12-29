module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  util = require 'util'
  commons = require('pimatic-plugin-commons')(env)

  class PimaticMeshContact extends env.devices.ContactSensor

    constructor: (@config, @plugin, lastState) ->
      @debug = @plugin.config.debug ? @plugin.config.__proto__.debug
      @_base = commons.base @, @config.class
      console.log "@debug", @debug
      @_base.debug "initializing:", util.inspect(@config) if @debug
      @id = @config.id
      @name = @config.name
      @remotePimatic = @config.remotePimatic
      @remoteDevice = @config.remoteDeviceId
      @_contact = lastState?.contact?.value or off
      super()

      @plugin.remotes[@remotePimatic].on @remoteDevice, (event) =>
        @emit event.attributeName, event.value

    getContact: () ->
      return Promise.resolve @_contact

    setContact: (value) ->
      @_base.debug 'set contact:', value

      @plugin.remotes[@remotePimatic].action @remoteDevice, "contact", {
        contact: value
      }

    destroy: () =>
      super()
