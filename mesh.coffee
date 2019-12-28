# pimatic-mesh plugin
module.exports = (env) ->

  _ = env.require 'lodash'
  Mesh = require('./mesh-connections')(env)
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
      @mesh = new Mesh(@config, @)
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
        #devices = @messenger.getDevices()
        #env.logger.info "#{devices.length} devices discovered"
        #        tbd
      )

  # ###Finally
  # Create a instance of plugin
  return new PimaticMeshPlugin