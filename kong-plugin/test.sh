# You can test the plugin using Kong Gateway by running the following command in your terminal:

cd kong-plugin-shopify-hmac/kong-plugin
pongo init
pongo up

# This will enter you into a containerized Kong environment where you can run tests and interact with Kong Gateway.
pongo shell

# Your terminal is now running a shell inside the Kong Gateway container. Your shell prompt should change, showing you the Kong Gateway version, the host plugin directory, and current path inside the container. For example, your prompt may look like the following:
# [Kong-3.9.0:my-plugin:/kong]$

kms

# If you get following error after running kms command:
  # # Error: nginx configuration is invalid (exit code 1):
  # # nginx: the configuration file /kong-plugin/servroot/nginx.conf syntax is ok
  # # nginx: [emerg] bind() to unix:/kong-plugin/servroot/sockets/we failed (95: Operation not supported)
  # # nginx: configuration file /kong-plugin/servroot/nginx.conf test failed

# Run this inside container to avoid above socket error. 
# export KONG_PREFIX=/tmp/kong

# Now you can run kms again
# kms

# Validate that the plugin is installed by querying the Admin API using curl and filtering the response with jq: 
curl -s localhost:8001 | \
  jq '.plugins.available_on_server."shopify-hmac-auth"'

# you get a response like below if the plugin is installed successfully:
# {
#   "priority": 1000,
#   "version": "1.0.0"
# }


# Still within the Kong Gateway container’s shell, add a new Gateway Service: 
curl -X POST "http://localhost:8001/services" \
     --no-progress-meter --fail-with-body  \
     --json '{
       "name": "shopify_example_service",
       "url": "https://httpbin.konghq.com"
     }'


# Enable the custom plugin on the example_service Service: 
curl -X POST "http://localhost:8001/services/shopify_example_service/plugins" \
     --no-progress-meter --fail-with-body  \
     --json '{
       "name": "shopify-hmac-auth",
       "config": { "secret": "hush" }
     }'
# Response should be like below:
# {"created_at":1765920780,"updated_at":1765920780,"retries":5,"port":443,"enabled":true,"write_timeout":60000,"client_certificate":null,"ca_certificates":null,"protocol":"https","path":null,"id":"3a6ec8d8-0c26-4a6d-96f0-ff47e39f39cf","tls_verify":null,"connect_timeout":60000,"tls_verify_depth":null,"read_timeout":60000,"name":"shopify_example_service","tags":null,"host":"httpbin.konghq.com"}

# Add a new Route for sending requests through the example_service: 

curl -X POST "http://localhost:8001/services/shopify_example_service/routes" \
     --no-progress-meter --fail-with-body  \
     --json '{
       "name": "shopify_example_route",
       "paths": [
         "/mock"
       ]
     }'
# Response should be like below:
# {"created_at":1765921223,"updated_at":1765921223,"preserve_host":false,"path_handling":"v0","destinations":null,"regex_priority":0,"service":{"id":"3a6ec8d8-0c26-4a6d-96f0-ff47e39f39cf"},"methods":null,"strip_path":true,"headers":null,"paths":["/mock"],"request_buffering":true,"response_buffering":true,"https_redirect_status_code":426,"hosts":null,"id":"92d3ac0c-0315-4357-99a0-7eddeb75d4ec","sources":null,"tags":null,"name":"example_route","protocols":["http","https"],"snis":null}

# Send a request to test the behavior and use the -i flag to display the response headers: 
curl -i "http://localhost:8000/mock/anything" \
     --no-progress-meter --fail-with-body \
  -H "Content-Type: application/json" \
  -H "X-Shopify-Hmac-Sha256: wFm4eKfwLGyYqOJyoXCW38u4PMaCXzvVjZLwUGXVv9k=" \
  --data-binary {\"order\":{\"id\":123}}

# Response should be like below:
# HTTP/1.1 200 OK
# Content-Type: application/json
# Content-Length: 697
# Connection: keep-alive
# Server: gunicorn/19.9.0
# Date: Tue, 16 Dec 2025 21:52:51 GMT
# Access-Control-Allow-Origin: *
# Access-Control-Allow-Credentials: true
# X-Kong-Upstream-Latency: 294
# X-Kong-Proxy-Latency: 206
# Via: 1.1 kong/3.9.1
# X-Kong-Request-Id: c809db22fb8856426af2445096185552

# {
#   "args": {},
#   "data": "{\"order\":{\"id\":123}}",
#   "files": {},
#   "form": {},
#   "headers": {
#     "Accept": "*/*",
#     "Connection": "keep-alive",
#     "Content-Length": "20",
#     "Content-Type": "application/json",
#     "Host": "httpbin.konghq.com",
#     "User-Agent": "curl/8.5.0",
#     "X-Forwarded-Host": "localhost",
#     "X-Forwarded-Path": "/mock/anything",
#     "X-Forwarded-Prefix": "/mock",
#     "X-Kong-Request-Id": "c809db22fb8856426af2445096185552",
#     "X-Shopify-Hmac-Sha256": "wFm4eKfwLGyYqOJyoXCW38u4PMaCXzvVjZLwUGXVv9k="
#   },
#   "json": {
#     "order": {
#       "id": 123
#     }
#   },
#   "method": "POST",
#   "origin": "127.0.0.1",
#   "url": "http://localhost/anything"
# }


# =============================================== in case of invalid HMAC ===============================================

curl -i "http://localhost:8000/mock/anything"      --no-progress-meter --fail-with-body   -H "Content-Type: application/json"   -H "X-Shopify-Hmac-Sha256: wFm4eKfwLGyYqOJyoXCW38u4PMaCXzvVjZLwUGXVv9k="   --data-binary {\"order\":{\"id\":xxxxx123}}
# HTTP/1.1 403 Forbidden
# Date: Tue, 16 Dec 2025 21:49:49 GMT
# Content-Type: application/json; charset=utf-8
# Connection: keep-alive
# Content-Length: 36
# X-Kong-Response-Latency: 1
# Server: kong/3.9.1
# X-Kong-Request-Id: 837c1c193b7556116cfee5295b91994e

# curl: (22) The requested URL returned error: 403
# {"message":"Invalid HMAC signature"}