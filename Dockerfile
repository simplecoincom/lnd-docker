 
FROM golang:1.13-alpine as builder

LABEL maintainer="SimpleCoin <devops@simplecoin.com>"

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

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

# Expose lnd ports (p2p, rpc, rest).
EXPOSE 9735 10009 8080

RUN mkdir /data

# Copy the binaries and entrypoint from the builder image.
COPY --from=builder /go/bin/lncli /bin/
COPY --from=builder /go/bin/lnd /bin/

# Add bash.
RUN apk add --no-cache \
    bash

ENTRYPOINT ["lnd"]