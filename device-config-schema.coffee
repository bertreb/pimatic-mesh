module.exports = {
  title: "pimatic-remotes device config schemas"
  PimaticMeshSwitch: {
    title: "Mesh Switch"
    description: "Mesh SwitchDevice"
    type: "object"
    extensions: ["xLink", "xOnLabel", "xOffLabel"]
    properties:
      remotePimatic:
        description: "The id of the remote Pimatic"
        type: "string"
      remoteDeviceId:
        description: "The id of the remote switch device"
        type: "string"
  },
  PimaticMeshPresence: {
    title: "Mesh Presence"
    description: "Mesh PresenceDevice"
    type: "object"
    extensions: ["xLink", "xPresentLabel", "xAbsentLabel"]
    properties:
      remotePimatic:
        description: "The id of the remote Pimatic"
        type: "string"
      remoteDeviceId:
        description: "The id of the remote presence sensor"
        type: "string"
  },
  PimaticMeshContact: {
    title: "Mesh Contact"
    description: "Mesh ContactDevice"
    type: "object"
    extensions: ["xLink", "xOpenedLabel", "xClosedLabel"]
    properties:
      remotePimatic:
        description: "The id of the remote Pimatic"
        type: "string"
      remoteDeviceId:
        description: "The id of the remote contact sensor"
        type: "string"
  },
  PimaticMeshTemperature: {
    title: "Mesh TemperatureDevice"
    description: "Mesh Temperature"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      remotePimatic:
        description: "The id of the remote Pimatic"
        type: "string"
      remoteDeviceId:
        description: "The id of the remote temperature sensor"
        type: "string"
  },
  PimaticMeshDimmer: {
    title: "Mesh Dimmer"
    description: "Mesh DimmerDevice"
    type: "object"
    extensions: ["xLink"]
    properties:
      remotePimatic:
        description: "The id of the remote Pimatic"
        type: "string"
      remoteDeviceId:
        description: "The id of the remote dimmer"
        type: "string"
  },
  PimaticMeshVariables: {
    title: "Mesh VariablesDevice"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      remotePimatic:
        description: "The id of the remote Pimatic"
        type: "string"
      variables:
        description: "Variables to display"
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          required: ["name", "remoteDeviceId"]
          properties:
            name:
              description: "Name for the corresponding attribute."
              type: "string"
            remoteDeviceId:
              description: "The id of the remote variable "
              type: "string"
            remoteAttributeId:
              description: "The id of the remote attribute"
              type: "string"
            type:
              description: "The type of the variable."
              type: "string"
              default: "string"
              enum: ["string", "number"]
            unit:
              description: "The unit of the variable. Only works if type is a number."
              type: "string"
              required: false
            label:
              description: "A custom label to use in the frontend."
              type: "string"
              required: false
            acronym:
              description: "Acronym to show as value label in the frontend"
              type: "string"
              required: false
  }
}
