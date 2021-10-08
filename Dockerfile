FROM golang:1.17.2-alpine as builder

LABEL maintainer="SimpleCoin <devops@simplecoin.com>"

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

ARG CHECKOUT="master"

# Install dependencies and build the binaries.
RUN apk add --no-cache --update alpine-sdk \
    git \
    make \
    gcc \
&&  git clone https://github.com/lightningnetwork/lnd /go/src/github.com/lightningnetwork/lnd \
&&  cd /go/src/github.com/lightningnetwork/lnd \
&&  git checkout ${CHECKOUT} \
&&  make \
&&  make install tags="signrpc walletrpc chainrpc invoicesrpc kvdb_postgres"

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
    curl

ENTRYPOINT ["lnd"]
