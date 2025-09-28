-- shopify-hmac-auth-1.0.0-1.rockspec
package = "shopify-hmac-auth"
version = "1.0.0-1"
source = {
  url    = "git+https://github.com/yourusername/shopify-hmac-auth.git",
  branch = "main"
}
description = {
  summary = "Kong plugin to validate Shopify webhook HMAC signatures",
  detailed = [[
    This plugin validates incoming requests from Shopify using the X-Shopify-Hmac-Sha256 header.
    It ensures webhooks are authentic and prevents unauthorized access.
  ]],
  homepage = "https://github.com/yourusername/shopify-hmac-auth",
  license  = "MIT"
}
dependencies = {
  "lua >= 5.1",
  "kong >= 3.0"  -- adjust based on your target Kong version
}
build = {
  type = "builtin",
  modules = {
    ["kong.plugins.shopify-hmac-auth.handler"] = "kong/plugins/shopify-hmac-auth/handler.lua",
    ["kong.plugins.shopify-hmac-auth.schema"]  = "kong/plugins/shopify-hmac-auth/schema.lua",
    ["kong.plugins.shopify-hmac-auth.init"]    = "kong/plugins/shopify-hmac-auth/init.lua"
  }
}