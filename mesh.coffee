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
    "buttons": {
      id: "mesh-buttons-"
      name: "Mesh Button "
      class: "PimaticMeshButtons"
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
              when "buttons"
                addDeviceToDiscovery("buttons", device, key)
              else
                env.logger.debug 'instance not yet defined'
          #variables = remote.getVariables()
          for i, device of devices
            addVariableToDiscovery(device, key)
      )

      addVariableToDiscovery = (device, key) =>
        config =
          class: deviceConfigTemplates["variables"].class
          name: "[" + key + "] "  + device.name
          id: key + "_" + device.id
          remotePimatic: key
        deviceAttributes = []
        for key, attr of device.attributes
          cleanUnit = if attr.unit? then (attr.unit).replace("\u00C2","") else ""
          deviceAttribute =
            name: attr.name
            type: attr.type
            remoteDeviceId: device.id
            remoteAttributeId: attr.name
            unit: cleanUnit
            label: attr.label ? ""
            acronym: attr.acronym ? ""
          deviceAttributes.push deviceAttribute
        config["variables"] = deviceAttributes
        if not @inConfig(config.id, config.class)
          @framework.deviceManager.discoveredDevice( 'mesh-variables ', "[#{config.remotePimatic}] #{device.config.id}", config )

      addDeviceToDiscovery = (meshClass, device, key) =>
        config =
          class: deviceConfigTemplates[meshClass].class
          name: "[" + key + "] "  + device.config.name
          id: key + "_" + device.config.id
          remotePimatic: key
          remoteDeviceId: device.config.id
        config["buttons"] = device.config.buttons if device.config.buttons?
        config["xConfirm"] = device.config.xConfirm if device.config.xConfirm?
        config["xLink"] = device.config.xLink if device.config.xLink?
        config["xOnLabel"] = device.config.xOnLabel if device.config.xOnLabel?
        config["xOffLabel"] = device.config.xOffLabel if device.config.xOffLabel?
        config["xPresentLabel"] = device.config.xPresentLabel if device.config.xPresentLabel?
        config["xAbsentLabel"] = device.config.xAbsentLabel if device.config.xAbsentLabel?
        config["xClosedLabel"] = device.config.xClosedLabel if device.config.xClosedLabel?
        config["xOpenedLabel"] = device.config.xOpenedLabel if device.config.xOpenedLabel?
        config["xAttributeOptions"] = device.config.xAttributeOptions if device.config.xAttributeOptions?

        env.logger.debug "Remote Device.config: " + JSON.stringify(device.config,null,2)

        if not @inConfig(config.id, config.class)
          @framework.deviceManager.discoveredDevice( 'mesh-'+meshClass+' ', "[#{config.remotePimatic}] #{device.config.id}", config )

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
      else if ((device.config.class).toLowerCase()).indexOf("buttons") >= 0
        return "buttons"
      else if ((device.config.class).toLowerCase()).indexOf("contact") >= 0
        return "contact"
      else if _.find(device.attributes,(a) => (a.name.toLowerCase()).indexOf("temp") >= 0)
        return "temperature"
      else
        return "unknown"

  return new PimaticMeshPlugin
