# kong-plugin-shopify-hmac-auth

A custom Kong Gateway plugin for validating Shopify webhook requests using HMAC signatures.

This plugin was created following the official standards outlined in the Kong Gateway documentation: 
[Set Up a Plugin Project](https://developer.konghq.com/custom-plugins/get-started/set-up-plugin-project/)

Further to above, [this blogpost on the Kong website](https://konghq.com/blog/custom-lua-plugin-kong-gateway) may also be helpful.

This plugin is tested using kong-pongo and is designed to work with the
[`kong-pongo`](https://github.com/Kong/kong-pongo) and
[`kong-vagrant`](https://github.com/Kong/kong-vagrant) development environments.

## Overview

Shopify webhooks include an `X-Shopify-Hmac-Sha256` header that contains a base64-encoded HMAC signature of the raw request body. This plugin verifies that signature using a shared secret to ensure the webhook is authentic and untampered.

Unlike Kong's built-in `hmac-auth` plugin, this plugin is tailored specifically for Shopify's webhook format.

## Features

- Verifies HMAC signature from `X-Shopify-Hmac-Sha256` header
- Uses raw request body for signature computation
- Rejects requests with missing or invalid signatures
- Lightweight and fast
- Compatible with DB-less and DB-backed Kong deployments

## Installation

### With LuaRocks

```bash
luarocks install kong-plugin-shopify-hmac
```
### With Kong gateway API

```bash
# Enable the custom plugin on the example_service Service: 
# Read more details in test.sh file on the github repository https://github.com/ajavedm/kong-plugin-shopify-hmac
curl -X POST "http://localhost:8001/services/shopify_example_service/plugins" \
     --no-progress-meter --fail-with-body  \
     --json '{
       "name": "shopify-hmac-auth",
       "config": { "secret": "hush" }
     }'
```
### Unit testing

```bash
# Install dependencies
# Clone the repository and install Pongo: https://github.com/Kong/kong-pongo
PATH=$PATH:~/.local/bin
git clone https://github.com/Kong/kong-pongo.git
mkdir -p ~/.local/bin
ln -s $(realpath kong-pongo/pongo.sh) ~/.local/bin/pongo
```

```bash
# Run tests
# Get a shell into your plugin repository, and run pongo, for example:
git clone https://github.com/ajavedm/kong-plugin-shopify-hmac.git
cd kong-plugin-shopify-hmac/kong-plugin
# auto pull and build the test images
pongo run
```

## Testing

```py
# Use this Python snippet to generate a correct HMAC for testing 
import hmac
import hashlib
import base64

secret = b"your_shopify_webhook_secret"
body = b'{"order":{"id":123}}'

digest = hmac.new(secret, body, hashlib.sha256).digest()
hmac_header = base64.b64encode(digest).decode()
print("X-Shopify-Hmac-Sha256:", hmac_header)
```

```bash
# Use this to send test request
curl -X POST http://localhost:8000/webhooks \
  -H "X-Shopify-Hmac-Sha256: $HMAC_HEADER" \
  -d '{"order":{"id":123}}'
```