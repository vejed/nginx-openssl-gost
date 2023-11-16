# nginx-openssl-gost
Nginx with OpenSSL and GOST encryption engine.

See built docker image at [vejed/nginx-proxy-gost](https://hub.docker.com/r/vejed/nginx-openssl-gost)


## Example of usage as forward proxy with auth at remote server by client certificate
1. Create file `nginx.conf.template` with following content:
```
server {
    listen 8080;
    server_name localhost;
    
    resolver ${NGINX_LOCAL_RESOLVERS};

    location / {       
        proxy_pass https://${CUSTOM_PROXY_HOST}$uri$is_args$args;

        proxy_ssl_certificate     /etc/nginx/certs/client.crt;
        proxy_ssl_certificate_key /etc/nginx/certs/client.key;

        proxy_ssl_trusted_certificate /etc/nginx/certs/ca.crt;
        proxy_ssl_verify       on;
        proxy_ssl_verify_depth 2;

        proxy_ssl_session_reuse on;
    }
}
```
2. Create directory `certs` and put 3 files in it:
    - `client.crt` - client certificate
    - `client.key` - client private key
    - `ca.crt` - CA certificate used by server
3. Run forward proxy at localhost:8080 (change value of `CUSTOM_PROXY_HOST` to your remote server host)
```sh
$ docker run \
  -e CUSTOM_PROXY_HOST=gost.example.com \
  -e NGINX_ENTRYPOINT_LOCAL_RESOLVERS=1 \
  -p 8080:8080 \
  -v "$PWD"/nginx.conf.template:/etc/nginx/templates/default.conf.template:ro \
  -v "$PWD"/certs:/etc/nginx/certs:ro \
  -e NGINX_ENTRYPOINT_LOCAL_RESOLVERS=1 \
  --name nginx-openssl-gost \
  --rm \
  vejed/nginx-openssl-gost
```
4. Make requests to localhost:8080 as to target remote server, SSL GOST encryption will be automatically made by nginx. The following code
```
$ curl http://localhost:8080/some_path?a=val
```
will actually make request to `https://gost.example.com/some_path?a=val`
