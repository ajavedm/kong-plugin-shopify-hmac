-- schema.lua
local typedefs = require "kong.db.schema.typedefs"

local PLUGIN_NAME = "shopify-hmac-auth"

local schema = {
  name = PLUGIN_NAME,
  fields = {
    { consumer = typedefs.no_consumer },
    {
      protocols = typedefs.protocols_http,
    },
    {
      config = {
        type = "record",
        fields = {
          {
            secret = {
              type = "string",
              required = true,
              encrypted = true,
              referenceable = true,
              description = "The API secret provided by Shopify for webhook verification."
            }
          }
        }
      }
    }
  },
  entity_checks = {}
}

return schema