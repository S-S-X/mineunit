FROM alpine:latest as build
USER root
ENV USER=root
RUN apk add --no-cache build-base git lua-dev luarocks5.1 lua5.1-sec
RUN luarocks-5.1 install luasocket
RUN luarocks-5.1 install luacov
RUN luarocks-5.1 install busted 2.0.0-1
RUN luarocks-5.1 install --server https://luarocks.org/dev mineunit

# Mineunit base
FROM alpine:latest
COPY --from=build /usr/local /usr/local
RUN adduser -D mineunit
RUN apk add --no-cache lua5.1

# Alpine is fine but image size could still be optimized if needed
#RUN rm -rf /var/cache/apk
#FROM scratch
#COPY --from=mineunit / /

USER mineunit
WORKDIR /home/mineunit
#ENTRYPOINT ["mineunit"]
ENTRYPOINT ["sh", "-l"]
