# Change Log

## 1.2.0
- change version scheme
- [Add labels to k8s_metadata](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/pull/83)
- [Add source_host to conf.d/systemd/source.containers.conf](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/pull/84)
- minor refactoring and testing
- upgrade fluent-plugin-sumologic_output to latest (1.3.1)
- expose additional configuration options to provide more control over fluent-plugin-kubernetes_metadata_filter using default values (fixes #80 and #35)

## 1.18
- add FluentD S3 Output plugin to give more output options.   

## 1.17
- [fix #69 by upgrading sumologic fluentd output to 1.1.1 which contains fix to handle json parsing correctly](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/commit/498bd09fc2f353f0986ef3a9c583e4fb8ce7b401)

## 1.16
-[Enable ability to configure enable_stat_watcher on in_tail plugins to workaround issue where inotify may hang.](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/commit/b963866aea0587d079913f87ca1a60b4d8afb982)

## 1.15
-[Expose environment variable to configure proxy_uri in sumo out configuration](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/issues/65)
-[Allow container path for in_tail plugin to be configured via environment variable.  Default to current value for backwards compatibility.](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/issues/64)

## 1.14
-[kubernetes_sumologic plugin always adds a timestamp field to json logs](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/issues/61)

## 1.13
-[Add ntp and timesyncd to systemd services](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/pull/59#pullrequestreview-115374648)
-[Updates to new Audit Logging format](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/commit/90cc454927055cd337a91942b285e6b57264e8c5)

## 1.12
-[Allow hand picked data to be sent to sumo when certain exclusions apply](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/pull/58)

## 1.11
-[upgrade metadata filter plugin to address #54](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/commit/eb7a69ce5b36a9d8150bd0a0b62f98fb18d35367)

## 1.10
- [add missing exclude options to kubelet logs](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/commit/ced3304f1e64173554a8dee6367c785945f3ce99)
- [Use multi-stage build to eliminate build tools from final image](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/pull/57)

## 1.9
- base docker image was quite stale, this release bumps to 1.1.3 and anchors the plugins to specific versions.  Same versions from 1.8 used, this just enforces consistency.
- ensure read_from_head in systemd respects setting via environment variable 

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