ARG ALPINE_VERSION=3.18
ARG NGINX_VERSION=1.25


FROM alpine:${ALPINE_VERSION} AS gost-builder

WORKDIR /src

ARG GOST_ENGINE_COMMT=2a8a5e0ecaa3e3d6f4ec722a49aa72476755c2b7
ARG GOST_ENGINE_SHA256=47b42fc3b9a49cd88f2e7f11c908a8c347df40e500cce058ed5e7a15d0d32ee6
ARG LIBPROV_COMMIT=d46906398e2ae483bf150b1de2c1a17c2c1715d4
ARG LIBPROV_SHA256=d852981fb7de5a0ba075c2718a513e263c56686544b60e77365063648478ff79

RUN apk add --no-cache --virtual .build-deps \
      cmake            \
      alpine-sdk       \
      openssl-dev



RUN wget "https://github.com/gost-engine/engine/archive/${GOST_ENGINE_COMMT}.zip" -O gost-engine.zip \
  && echo "${GOST_ENGINE_SHA256}" gost-engine.zip | sha256sum -c - \
  && unzip gost-engine.zip -d ./ \
  && rm gost-engine.zip \
  && mv "engine-${GOST_ENGINE_COMMT}" gost-engine \
  \
  && wget "https://github.com/provider-corner/libprov/archive/${LIBPROV_COMMIT}.zip" -O libprov.zip \
  && echo "${LIBPROV_SHA256}" libprov.zip | sha256sum -c - \
  && unzip libprov.zip -d ./ \
  && rm libprov.zip \
  && mv "libprov-${LIBPROV_COMMIT}"/* gost-engine/libprov/ \
  \
  && mkdir gost-engine/build \
  && cd gost-engine/build \
  && cmake -DCMAKE_BUILD_TYPE=Release .. \
  && cmake --build . --config Release \
  && cmake --build . --target install --config Release \
  \
  && mkdir /app \
  && cp bin/gost.so /app/ \
  \
  && rm -rf /src \
  \
  && echo "Building gost.so done"
  
RUN apk del --no-network .build-deps




FROM nginx:${NGINX_VERSION}-alpine${ALPINE_VERSION} as runner

RUN apk add --no-cache openssl

COPY --from=gost-builder /app/gost.so "/usr/lib/engines-3"

COPY openssl.cnf /etc/ssl/openssl.cnf


#CMD ["sh", "-c", "(while true; do sleep 1; done);"]
