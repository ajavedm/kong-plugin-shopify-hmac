
local Schema = require "kong.db.schema"

local function get_config_schema(s)
  for _, f in ipairs(s.fields) do
    if f.config then
      return f.config
    end
  end
  return nil, "config field not found in plugin schema"
end

-- pull the local function captured by the closure:
local function extract_upvalue(func, upname)
  for i = 1, 100 do
    local name, val = debug.getupvalue(func, i)
    if not name then break end
    if name == upname then return val end
  end
end

describe("Shopify HMAC Plugin", function()
  local schema
  local handler

  setup(function()
    local ok_schema, err_schema = pcall(function()
      schema = require("kong.plugins.shopify-hmac-auth.schema")
    end)
    assert.is_true(ok_schema, "Failed to load schema: " .. (err_schema or ""))

    local ok_handler, err_handler = pcall(function()
      handler = require("kong.plugins.shopify-hmac-auth.handler")
    end)
    assert.is_true(ok_handler, "Failed to load handler: " .. (err_handler or ""))
  end)

  describe("schema validation", function()
    it("should accept valid config", function()
      local cfg_schema, find_err = get_config_schema(schema)
      assert.is_truthy(cfg_schema, find_err)

      local validator, new_err = Schema.new(cfg_schema)
      assert.is_truthy(validator, "schema construction failed: " .. (new_err or "unknown error"))

      local ok, err = validator:validate({ secret = "mysecret123" })
      assert.is_true(ok)
      assert.is_nil(err)
    end)

    it("should reject missing secret", function()
      local cfg_schema = assert(get_config_schema(schema))
      local validator = assert(Schema.new(cfg_schema))

      local ok, err = validator:validate({})
      -- inner-record failures may return nil, not strictly false
      assert.is_falsy(ok)
      assert.matches("required", err.secret)
    end)
  end)

  describe("secure_compare", function()
    local secure_compare

    before_each(function()
      secure_compare = extract_upvalue(handler.access, "secure_compare")
      assert.is_function(secure_compare)
    end)

    it("should return true for equal strings", function()
      assert.is_true(secure_compare("abc", "abc"))
      assert.is_true(secure_compare("", ""))
    end)

    it("should return false for different strings", function()
      assert.is_false(secure_compare("abc", "def"))
      assert.is_false(secure_compare("abc", "abcd"))
    end)
  end)
end)
