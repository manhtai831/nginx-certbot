#!/bin/sh
set -e

(
  while :; do
    sleep 6h
    echo "Reload nginx..."
    nginx -t && nginx -s reload
  done
) &

nginx -g "daemon off;"