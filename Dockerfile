 
FROM golang:1.13-alpine as builder

LABEL maintainer="SimpleCoin <devops@simplecoin.com>"

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo
ENV LND_DATA=/home/bitcoin/.bitcoin

# Install dependencies and install/build lnd.
RUN apk add --no-cache --update alpine-sdk \
    git \
    make 

# Fetch lnd go lib
RUN go get -d github.com/lightningnetwork/lnd 

RUN cd /go/src/github.com/lightningnetwork/lnd \
&&  make \
&&  make install tags="signrpc walletrpc chainrpc invoicesrpc kvdb_etcd" 

# Start a new, final image to reduce size.
FROM alpine as final

# Expose lnd ports (server, rpc).
EXPOSE 9735 10009

# Copy the binaries and entrypoint from the builder image.
COPY --from=builder /go/bin/lncli /bin/
COPY --from=builder /go/bin/lnd /bin/

# Add bash.
RUN apk add --no-cache \
    bash

COPY docker-entrypoint.sh /entrypoint.sh

VOLUME ["/home/lnd/.lnd"]

EXPOSE 8332 8333 18332 18333 18443 18444

ENTRYPOINT ["/entrypoint.sh"]

CMD ["lnd"]