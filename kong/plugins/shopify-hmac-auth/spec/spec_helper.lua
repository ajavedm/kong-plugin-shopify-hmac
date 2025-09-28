-- spec/spec_helper.lua
ngx = {
  encode_base64 = function(data)
    return require("mime").b64(data)
  end,
  decode_base64 = function(data)
    return require("mime").unb64(data)
  end
}

-- Optional: mock kong later
kong = {
  response = { exit = function() end },
  log = {
    debug = function() end,
    err = function() end
  },
  req = {}
}