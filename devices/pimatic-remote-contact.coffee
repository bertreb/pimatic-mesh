module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  util = require 'util'
  commons = require('pimatic-plugin-commons')(env)

  # Device class representing an UniPi relay switch
  class PimaticRemoteContact extends env.devices.ContactSensor

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
      #@mesh = @plugin.mesh.remotes[@config.remotePimatic].socket
      super()

      @plugin.mesh.on @config.remoteDeviceId, (event) =>
        @emit event.attributeName, event.value

    getContact: () ->
      return Promise.resolve @_contact

    setContact: (value) ->
      @_base.debug 'set presence:', value

      @plugin.mesh.action @config.remotePimatic, @config.remoteDeviceId, "contact", {
        contact: value
      }

    destroy: () =>
      super()
