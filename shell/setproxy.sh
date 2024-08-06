#!/bin/sh

proxy_string="$1"
no_proxy="$2"

if [ -z "$proxy_string" ]; then
  echo "  Set: eval \$($(basename $0) http://someproxy:8080)"
  echo "Unset: eval \$($(basename $0) --unset)"
  exit 1
elif [ "$proxy_string" == "--unset" ]; then
  echo "unset ftp_proxy http_proxy https_proxy no_proxy"
else
  echo "export ftp_proxy=\"$proxy_string\""
  echo "export http_proxy=\"$proxy_string\""
  echo "export https_proxy=\"$proxy_string\""
  if [ -n "$no_proxy" ]; then
    echo "no_proxy=\"$no_proxy\""
  fi
fi
