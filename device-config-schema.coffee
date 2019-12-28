module.exports = {
  title: "pimatic-remotes device config schemas"
  PimaticRemoteSwitch: {
    title: "Remote Switch"
    description: "Remote Switch"
    type: "object"
    extensions: ["xLink", "xOnLabel", "xOffLabel"]
    properties:
      remotePimatic:
        description: "The id of the remote Pimatic"
        type: "string"
        default: "default"
      remoteDeviceId:
        description: "The id of the remote switch device"
        type: "string"
  },
  PimaticRemotePresence: {
    title: "Remote Presence"
    description: "Remote Presence"
    type: "object"
    extensions: ["xLink", "xPresentLabel", "xAbsentLabel"]
    properties:
      remotePimatic:
        description: "The id of the remote Pimatic"
        type: "string"
        default: "default"
      remoteDeviceId:
        description: "The id of the remote presence sensor"
        type: "string"
  },
  PimaticRemoteContact: {
    title: "Remote Contact"
    description: "Remote Contact"
    type: "object"
    extensions: ["xLink", "xOpenedLabel", "xClosedLabel"]
    properties:
      remotePimatic:
        description: "The id of the remote Pimatic"
        type: "string"
        default: "default"
      remoteDeviceId:
        description: "The id of the remote contact sensor"
        type: "string"
  },
  PimaticRemoteTemperature: {
    title: "Remote Temperature"
    description: "Remote Temperature"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      remotePimatic:
        description: "The id of the remote Pimatic"
        type: "string"
        default: "default"
      remoteDeviceId:
        description: "The id of the remote temperature sensor"
        type: "string"
  },
  PimaticRemoteDimmer: {
    title: "Remote Dimmer"
    description: "Remote Dimmer"
    type: "object"
    extensions: ["xLink"]
    properties:
      remotePimatic:
        description: "The id of the remote Pimatic"
        type: "string"
        default: "default"
      remoteDeviceId:
        description: "The id of the remote dimmer"
        type: "string"
  },
  PimaticRemoteVariables: {
    title: "VariablesDevice config"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      remotePimatic:
        description: "The id of the remote Pimatic"
        type: "string"
        default: "default"
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
