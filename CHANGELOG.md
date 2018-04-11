# Change Log

## 1.9
- base docker image was quite stale, this release bumps to 1.1.3 and anchors the plugins to specific versions.  Same versions from 1.8 used, this just enforces consistency.

## 1.8
- [Change default FLUSH_INTERVAL to 5s](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/commit/7b100306d6c84335ee0d4ec6724a3218e8028893)
- [Handle possible timeout from Concat Plugin and ensure all logs resume the flow thru rest of pipeline when this occurs](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/commit/7b100306d6c84335ee0d4ec6724a3218e8028893)
- [Allow the time_key field to be defined via environment variables](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/pull/53)

## 1.7
- [Fix typo in sumologic kubernetes filter](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/pull/51)

## v1.6
 - upgrade fluentd-sumo_output plugin to latest 1.0, adds support for millisecond precision.
 - add support for kubernetes audit log

## v1.5

- [Setting up tolerations](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/pull/43)
- [add some etcdadm services](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/pull/41)
- [Add RBAC permissions ](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/pull/40)

## v1.4

- [add support for multi-line log messages ](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/pull/33)

## v1.3

- [fix empty? checks on nil values by switching defaults to empty strings](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/pull/32)

## v1.2

- [Enable monitoring endpoints](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/pull/28)

## v1.1

- [Add support for systemd](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/pull/21).

## v1.0

- Initial tag