# pimatic-mesh
A plugin for interconnecting pimatic systems.
This plugin is based on pimatic-remote from [mwittig](https://github.com/mwittig/pimatic-remote) and is extended with devices and a multi-remote capability.

The pimatic-mesh plugin connects one or more remote Pimatic systems to the Pimatic system of this plugin.
In the plugin the most common devices are supported.
There are two typical use cases for this plugin

1. When you want to migrate from a node v4 system to a node v8/v10 system, sometimes one or more plugins are not supporting node v8/v10 and these plugin are blocking the upgrade. With this plugin you can leave the devices, of those node v4 only plugins, on the old system and use pimatic-mesh to connect them to the new system. There's a tradeoff. Because you create new device types for the (remote) devices, you need to update the device config with the new mesh  device classes. The mesh device ID and Name can stay the same, so rules do not have to change.

2. Create a distributed pimatic system. The plugin can be installed on more than 1 system and so you can configure backup, distribute complexity and get flexibility for future migration. Mesh devices can be link to each other system, but be careful not to create loops.

The pimatic remote systems can be configured in the plugin config. Per remote you need to configure the following parameters.

```
{
  "id": name for the remote system that is used in the mesh device setup
  "url": the url of the remote system
  "username": the Pimatic username for the remote system
  "password": the Pimatic password for the remote system
}
```

Per mesh device you can choose which remote Pimatic system will be used (via the 'id').

The supported mesh devices are switch, contact, dimmer, presence, temperature and variable. The remote switch and dimmer can be controlled from the switch and dimmer mesh device. From all devices you get data like state, level, etc, depending on the device type.
Variables from remote devices can be obtained via the mesh variables device.

An example.
You configured the plugin for the remote Pimatic and 'id' it as 'pimatic1'.
You want the data of a Luftdaten device from that remote system. The device id is 'airquality-outside-home' and the attributes you want are 'PM10' and 'PM25'.
You create a mesh variables device with the following config.

```
{
  "id": "air-quality",
  "name": "air quality",
  "class": "PimaticRemoteVariables"
  "remotePimatic": "pimatic1",
  "variables": [
    {
      "name": "pm10",
      "remoteDeviceId": "airquality-outside-home",
      "remoteAttributeId": "PM10",
      "type": "number"
    }
    {
      "name": "pm25",
      "remoteDeviceId": "airquality-outside-home",
      "remoteAttributeId": "PM25",
      "type": "number"
    }
  ],
  "xAttributeOptions": []
}
```

Now you created a mesh device with the id "air-quality" and the attributes "pm10" and "pm25".
The pm10 and pm25 data will come from the remote system and will become visible as soon as the remote systems values change.
