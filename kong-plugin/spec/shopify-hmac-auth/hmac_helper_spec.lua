-- spec/hmac_helper_spec.lua

local helpers = require "spec.shopify-hmac-auth.spec_helper"
local ngx = helpers.ngx
-- local kong = helpers.kong

local resty_sha256 = require "resty.sha256"
local bit = require "bit"

-- Copy your hmac_sha256 function for testing
local function hmac_sha256(key, message)
  local blocksize = 64
  if #key > blocksize then
    local sha256 = resty_sha256:new()
    sha256:update(key)
    key = sha256:final()
  end

  key = key .. string.rep("\0", blocksize - #key)
  local o_key_pad = ""
  local i_key_pad = ""

  for i = 1, blocksize do
    local byte = string.byte(key, i)
    o_key_pad = o_key_pad .. string.char(bit.bxor(byte, 0x5c))
    i_key_pad = i_key_pad .. string.char(bit.bxor(byte, 0x36))
  end

  local sha256 = resty_sha256:new()
  sha256:update(i_key_pad .. message)
  local inner = sha256:final()

  sha256 = resty_sha256:new()
  sha256:update(o_key_pad .. inner)
  return sha256:final()
end

describe("HMAC-SHA256 Helper", function()
  it("should generate correct Base64-encoded HMAC for known input", function()
    local secret = "hush"
    local body = '{"order":{"id":123}}'
    local digest = hmac_sha256(secret, body)
    local encoded = ngx.encode_base64(digest)  -- includes padding

    -- Known good value generated via Python
    -- python3 -c "import hmac, hashlib, base64; print(base64.b64encode(hmac.new(
    --   b'hush', b'{\"order\":{\"id\":123}}', hashlib.sha256).digest()).decode())"
    local expected = "wFm4eKfwLGyYqOJyoXCW38u4PMaCXzvVjZLwUGXVv9k="

    assert.equal(expected, encoded)
  end)

  it("should handle empty body", function()
    local secret = "abc"
    local body = ""
    local digest = hmac_sha256(secret, body)
    local encoded = ngx.encode_base64(digest)
    assert.is_not_nil(encoded)
    assert.equal(44, #encoded)  -- Base64 of 32-byte SHA256 → 44 chars
  end)
end)