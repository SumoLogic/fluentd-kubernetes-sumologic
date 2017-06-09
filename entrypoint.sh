#!/bin/bash
if [ $# -gt 0 ] && [ "${1:0:1}" != "-" ]; then
  exec $@
else
  cd `dirname $0`

  if [ $FLUENTD_SOURCE != file ] && [ $FLUENTD_SOURCE != systemd ]; then
    echo "Unknown source '$FLUENTD_SOURCE'"
    if [ -e /dev/termination-log ]; then
      echo "Unknown source '$FLUENTD_SOURCE'" >/dev/termination-log
    fi
    exit 1
  fi

  exec fluentd -c /fluentd/etc/fluent.$FLUENTD_SOURCE.conf -p /fluentd/plugins $FLUENTD_OPT
fi
