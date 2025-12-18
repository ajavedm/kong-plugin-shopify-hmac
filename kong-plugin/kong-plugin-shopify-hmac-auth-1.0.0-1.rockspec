-- kong-plugin-shopify-hmac-1.0.0-1.rockspec

local plugin_name = "shopify-hmac-auth"
local package_name = "kong-plugin-" .. plugin_name
local package_version = "1.0.0"
local rockspec_revision = "1"

local github_account_name = "ajavedm"
local github_repo_name = "kong-plugin-shopify-hmac"
-- local git_checkout = package_version == "dev" and "main" or package_version
local git_checkout = "main"


package = package_name
version = package_version .. "-" .. rockspec_revision

source = {
  url = "git+https://github.com/"..github_account_name.."/"..github_repo_name..".git",
  branch = git_checkout,
}

description = {
  summary = "Kong plugin to validate Shopify webhook HMAC signatures",
  detailed = [[
    This plugin validates incoming requests from Shopify using the X-Shopify-Hmac-Sha256 header.
    It ensures webhooks are authentic and prevents unauthorized access.
  ]],
  homepage = "https://github.com/ajavedm/kong-plugin-shopify-hmac",
  -- homepage = "https://"..github_account_name..".github.io/"..github_repo_name,
  license  = "MIT"
}
dependencies = {
  "lua >= 5.1",
  "kong >= 3.4.2"
}
build = {
  type = "builtin",
  modules = {
    ["kong.plugins.shopify-hmac-auth.handler"] = "kong/plugins/shopify-hmac-auth/handler.lua",
    ["kong.plugins.shopify-hmac-auth.schema"]  = "kong/plugins/shopify-hmac-auth/schema.lua"
    -- TODO: add any additional code files added to the plugin
    -- ["kong.plugins."..plugin_name..".handler"] = "kong/plugins/"..plugin_name.."/handler.lua",
    -- ["kong.plugins."..plugin_name..".schema"] = "kong/plugins/"..plugin_name.."/schema.lua",
  }
}