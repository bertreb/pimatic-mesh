module.exports = {
  title: "pimatic-mesh plugin config options"
  type: "object"
  properties:
    debug:
      description: "Debug mode. Writes debug message to the pimatic log"
      type: "boolean"
      default: false
    remotes:
      description: "List of remote Pimatic systems"
      type: "array"
      format: "table"
      items:
        type: "object"
        properties:
          id:
            description: "Id for the remote Pimatic system"
            type: "string"
          url:
            description: "The URL of the remote pimatic server"
            type: "string"
          username:
            description: "The username to be used for the authentication with the remote pimatic server"
            type: "string"
          password:
            description: "The password to be used for the authentication with the remote pimatic server"
            type: "string"
}
