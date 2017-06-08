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

  if [ ! -z $FLUENTD_USER_CONFIG_DIR ] && [ -d $FLUENTD_USER_CONFIG_DIR ]; then
    cp -r $FLUENTD_USER_CONFIG_DIR/* /fluentd/conf.d/user
  fi

  exec fluentd -c /fluentd/etc/fluent.$FLUENTD_SOURCE.conf -p /fluentd/plugins $FLUENTD_OPT
fi
