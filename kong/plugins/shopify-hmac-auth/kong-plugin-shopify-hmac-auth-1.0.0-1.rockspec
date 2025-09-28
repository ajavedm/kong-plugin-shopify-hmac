-- kong-plugin-shopify-hmac-1.0.0-1.rockspec
package = "kong-plugin-shopify-hmac"
version = "1.0.0-1"
source = {
  url    = "git+https://github.com/ajavedm/kong-plugin-shopify-hmac.git",
  branch = "main"
}
description = {
  summary = "Kong plugin to validate Shopify webhook HMAC signatures",
  detailed = [[
    This plugin validates incoming requests from Shopify using the X-Shopify-Hmac-Sha256 header.
    It ensures webhooks are authentic and prevents unauthorized access.
  ]],
  homepage = "https://github.com/ajavedm/kong-plugin-shopify-hmac",
  license  = "MIT"
}
dependencies = {
  "lua >= 2.1.0-20220411",
  "kong >= 3.4.2"
}
build = {
  type = "builtin",
  modules = {
    ["kong.plugins.shopify-hmac-auth.handler"] = "kong/plugins/shopify-hmac-auth/handler.lua",
    ["kong.plugins.shopify-hmac-auth.schema"]  = "kong/plugins/shopify-hmac-auth/schema.lua",
    ["kong.plugins.shopify-hmac-auth.init"]    = "kong/plugins/shopify-hmac-auth/init.lua"
  }
}