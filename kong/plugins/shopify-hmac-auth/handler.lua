-- handler.lua
local typedefs = require "kong.db.schema.typedefs"
local resty_sha256 = require "resty.sha256"
local str = require "resty.string"
local bit = require "bit"  -- Added: required for bxor

local ShopifyHmacAuth = {
  PRIORITY = 1000,
  VERSION = "1.0.0",
}

-- Local HMAC-SHA256 implementation (same as yours, fixed)
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
  return sha256:final()  -- Returns binary string
end

-- Secure constant-time comparison (simple version)
local function secure_compare(a, b)
  if #a ~= #b then
    return false
  end
  local diff = 0
  for i = 1, #a do
    diff = bit.bor(diff, bit.bxor(string.byte(a, i), string.byte(b, i)))
  end
  return diff == 0
end

function ShopifyHmacAuth:access(conf)
  local headers = ngx.req.get_headers()
  local shopify_hmac = headers["x-shopify-hmac-sha256"]

  if not shopify_hmac or shopify_hmac == "" then
    return kong.response.exit(401, { message = "Missing X-Shopify-Hmac-Sha256 header" })
  end

  -- Read request body
  ngx.req.read_body()
  local body = ngx.req.get_body_data()

  -- Fallback if body was spooled to disk
  if not body then
    local body_file = ngx.req.get_body_file()
    if body_file then
      local file, err = io.open(body_file, "rb")
      if not file then
        return kong.response.exit(500, { message = "Cannot open body file: " .. (err or "") })
      end
      body = file:read("*all")
      file:close()
    else
      return kong.response.exit(400, { message = "No request body found" })
    end
  end

  -- Compute expected HMAC
  local digest = hmac_sha256(conf.secret, body)
  local encoded = ngx.encode_base64(digest, false)  -- Don't strip padding, shopify send header with padding i.e. xxxxxx=

  -- Compare securely
  if not secure_compare(encoded, shopify_hmac) then
    return kong.response.exit(403, { message = "Invalid HMAC signature" })
  end

  -- Success: proceed
  kong.log.debug("Shopify HMAC validation passed")
end

return ShopifyHmacAuth