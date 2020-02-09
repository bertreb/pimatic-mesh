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
          env.logger.debug "classType: " + './devices/' + filename
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
          devices = remote.getDevices()
          for i, device of devices
            switch @isInstanceOf(device)
              when "switch"
                addDeviceToDiscovery("switch", device, key)
              when "dimmer"
                addDeviceToDiscovery("dimmer", device, key)
              when "presence"
                addDeviceToDiscovery("presence", device, key)
              when "contact"
                addDeviceToDiscovery("contact", device, key)
              when "temperature"
                addDeviceToDiscovery("temperature", device, key)
              else
                env.logger.debug 'instance not yet defined'
      )

      addDeviceToDiscovery = (meshClass, device, key) =>
        config =
          class: deviceConfigTemplates[meshClass].class
          name: "[" + key + "] "  + device.config.name
          id: "_" + key + "_" + device.config.id
          remotePimatic: key
          remoteDeviceId: device.config.id
        if not @inConfig(config.id, config.class)
          @framework.deviceManager.discoveredDevice( 'pimatic-mesh ', "[#{config.remotePimatic}] #{device.config.id}", config )

      @framework.on 'destroy', () =>
        env.logger.debug "Close remote sockets and remove all listeners"
        for remote in @remotes
          remote.destroy()

    inConfig: (deviceID, className) =>
      deviceID = parseInt(deviceID)
      for device in @framework.deviceManager.devicesConfig
        if parseInt(device.deviceID) is deviceID and device.class is className
          env.logger.debug("device "+deviceID+" ("+className+") already exists")
          return true
      return false

    isInstanceOf: (device) =>
      if device.config.class is "MilightRGBWZone" or device.config.class is "MilightFullColorZone"
        return "dimmer"
      else if (device.config.class).indexOf("Dimmer") >= 0
        return "dimmer"
      else if (device.config.class).indexOf("Switch") >= 0
        return "switch"
      else if (device.config.class).indexOf("Presence") >= 0
        return "presence"
      else if ((device.config.class).toLowerCase()).indexOf("contact") >= 0
        return "contact"
      else if _.find(device.attributes,(a) => (a.name.toLowerCase()).indexOf("temp") >= 0)
        return "temperature"
      else
        return "unknown"

  return new PimaticMeshPlugin
