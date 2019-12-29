# pimatic-mesh plugin
module.exports = (env) ->

  _ = env.require 'lodash'
  Mesh = require('./mesh-connection')(env)
  commons = require('pimatic-plugin-commons')(env)
  deviceConfigTemplates = {
    "switch": {
      id: "remote-switch-"
      name: "Remote Switch "
      class: "PimaticRemoteSwitch"
    },
    "presence": {
      id: "remote-presence-"
      name: "Remote Presence "
      class: "PimaticRemotePresence"
    },
    "contact": {
      id: "remote-contact-"
      name: "Remote Contact "
      class: "PimaticRemoteContact"
    },
    "temperature": {
      id: "remote-temperature-"
      name: "Remote Temperature "
      class: "PimaticRemoteTemperature"
    },
    "dimmer": {
      id: "remote-dimmer-"
      name: "Remote Dimmer "
      class: "PimaticRemoteDimmer"
    },
    "variables": {
      id: "remote-variables-"
      name: "Remote variables "
      class: "PimaticRemoteVariables"
    }
  }

  # ###PimaticRemotePlugin class
  class PimaticMeshPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      
      @remotes = {}
      for remoteConfig in @config.remotes
        @remotes[remoteConfig.id] = new Mesh(remoteConfig, @)
        env.logger.info "remote: " + remoteConfig.id + " added, aantal remotes: " + _.size(@remotes)
      @debug = @config.debug || false
      @base = commons.base @, 'Plugin'
      @varMgr = @framework.variableManager

      # register devices
      deviceConfigDef = require("./device-config-schema")
      for key, device of deviceConfigTemplates
        do (key, device) =>
          className = device.class
          # convert camel-case classname to kebap-case filename
          filename = className.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();
          env.logger.info "classType: " + './devices/' + filename
          classType = require('./devices/' + filename)(env)
          @base.debug "Registering device class #{className}"
          @framework.deviceManager.registerDeviceClass(className, {
            configDef: deviceConfigDef[className],
            createCallback: (config, lastState) =>
              new classType(config, @, lastState)
          })

      # auto-discovery
      @framework.deviceManager.on('discover', (eventData) =>
        @framework.deviceManager.discoverMessage 'pimatic-mesh', 'Searching for devices'
        for key,remote of @remotes
          env.logger.info "Remote '#{remote.pimaticId}', '#{_.size(remote.getDevices())}' devices discovered"
      )

      @framework.on 'destroy', () =>
        env.logger.debug "Close remote sockets and remove all listeners"
        for remote in @remotes
          remote.destroy()

  # ###Finally
  # Create a instance of plugin
  return new PimaticMeshPlugin
