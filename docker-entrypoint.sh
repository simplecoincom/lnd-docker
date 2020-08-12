#!/bin/sh
set -e

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for lnd"

  set -- lnd "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "bitcoind" ]; then
  mkdir -p "$LND_DATA"
  chmod 700 "$LND_DATA"
  chown -R bitcoin "$LND_DATA"

  echo "$0: setting data directory to $LND_DATA"

  set -- "$@" -datadir="$LND_DATA"
fi

echo
exec "$@"