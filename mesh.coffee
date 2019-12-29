# pimatic-mesh plugin
module.exports = (env) ->

  _ = env.require 'lodash'
  Mesh = require('./mesh-connection')(env)
  commons = require('pimatic-plugin-commons')(env)
  deviceConfigTemplates = {
    "switch": {
      id: "mesh-switch-"
      name: "Mesh Switch "
      class: "PimaticMeshSwitch"
    },
    "presence": {
      id: "mesh-presence-"
      name: "Mesh Presence "
      class: "PimaticMeshPresence"
    },
    "contact": {
      id: "mesh-contact-"
      name: "Mesh Contact "
      class: "PimaticMeshContact"
    },
    "temperature": {
      id: "mesh-temperature-"
      name: "Mesh Temperature "
      class: "PimaticMeshTemperature"
    },
    "dimmer": {
      id: "mesh-dimmer-"
      name: "Mesh Dimmer "
      class: "PimaticMeshDimmer"
    },
    "variables": {
      id: "mesh-variables-"
      name: "Mesh Variables "
      class: "PimaticMeshVariables"
    }
  }

  # ###PimaticMeshPlugin class
  class PimaticMeshPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      
      @remotes = {}
      @enumRemotes = []
      for remoteConfig in @config.remotes
        @remotes[remoteConfig.id] = new Mesh(remoteConfig, @)
        @enumRemotes.push remoteConfig.id
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
          deviceConfigDef[className].properties.remotePimatic["enum"] = @enumRemotes
          @framework.deviceManager.registerDeviceClass(className, {
            configDef: deviceConfigDef[className],
            createCallback: (config, lastState) =>
              new classType(config, @, lastState)
          })

      # auto-discovery
      @framework.deviceManager.on('discover', (eventData) =>
        @framework.deviceManager.discoverMessage 'pimatic-mesh', 'Searching for devices'
        for key,remote of @remotes
          env.logger.info "Mesh'#{remote.pimaticId}', '#{_.size(remote.getDevices())}' devices discovered"
      )

      @framework.on 'destroy', () =>
        env.logger.debug "Close remote sockets and remove all listeners"
        for remote in @remotes
          remote.destroy()

  # ###Finally
  # Create a instance of plugin
  return new PimaticMeshPlugin
