
-- spec/shopify-hmac-auth/schema_spec.lua
local Schema = require "kong.db.schema"

local function get_config_schema(s)
  for _, f in ipairs(s.fields) do
    if f.config then
      return f.config
    end
  end
  return nil, "config field not found in plugin schema"
end

describe("Shopify HMAC Plugin schema validation", function()
  local plugin_schema

  setup(function()
    local ok, err = pcall(function()
      plugin_schema = require("kong.plugins.shopify-hmac-auth.schema")
    end)
    assert.is_true(ok, "Failed to load schema: " .. (err or ""))
    assert.is_table(plugin_schema, "schema did not return a table")
  end)

  it("accepts valid config", function()
    local cfg_schema, find_err = get_config_schema(plugin_schema)
    assert.is_truthy(cfg_schema, find_err)

    local validator, new_err = Schema.new(cfg_schema)
    assert.is_truthy(validator, "schema construction failed: " .. (new_err or "unknown error"))

    local ok, err = validator:validate({ secret = "mysecret123" })
    assert.is_true(ok)
    assert.is_nil(err)
  end)

  it("rejects missing secret", function()
    local cfg_schema = assert(get_config_schema(plugin_schema))
    local validator = assert(Schema.new(cfg_schema))

    local ok, err = validator:validate({})
    assert.is_falsy(ok)
    assert.matches("required", err.secret)
  end)
end)
