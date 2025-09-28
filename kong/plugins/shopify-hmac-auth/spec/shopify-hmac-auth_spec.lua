-- spec/shopify-hmac-auth_spec.lua
local utils = require "kong.tools.utils"

describe("Shopify HMAC Plugin", function()
  local schema
  local handler

  setup(function()
    -- Load schema and handler
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
      local validator = require("kong.db.schema").new(schema)
      local ok, err = validator:validate({ secret = "mysecret123" })
      assert.is_nil(err)
      assert.is_true(ok)
    end)

    it("should reject missing secret", function()
      local validator = require("kong.db.schema").new(schema)
      local ok, err = validator:validate({})
      assert.is_false(ok)
      assert.matches("required", err.secret)
    end)
  end)

  describe("secure_compare", function()
    local secure_compare

    before_each(function()
      -- Extract secure_compare from handler
      local hmachelper = handler:new()
      secure_compare = debug.getupvalue(hmachelper.access, 1)  -- gets `secure_compare`
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