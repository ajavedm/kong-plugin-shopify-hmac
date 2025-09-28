# kong-plugin-shopify-hmac-auth

A custom Kong Gateway plugin for validating Shopify webhook requests using HMAC signatures.

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
### Unit testing

```bash
# Install dependencies
luarocks install busted
luarocks install mime
```

```bash
# Run tests
busted spec/
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