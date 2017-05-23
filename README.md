# fluentd-Kubernetes-sumologic, a container to ship logs to [SumoLogic](http://www.sumologic.com)

This is a [fluentd](http://www.fluentd.org/) container, designed to run as a Kubernetes [DaemonSet](http://kubernetes.io/docs/admin/daemons/). It will run an instance of this container on each physical underlying host in the cluster. The goal is to pull all the kubelet, docker daemon and container logs from the host then to ship them off to [SumoLogic](https://www.sumologic.com/) in json or text format.

## Setup
### SumoLogic
First things first, you need a HTTP collector in SumoLogic that the container can send logs to via HTTP.

In Sumo, `Manage -> Collection -> Add Collector -> Hosted Collector`

Then you need to add a source to that collector, which would be a new `HTTP source`. This will give you a unique URL that can receive logs.

More details here: http://help.sumologic.com/Send_Data/Sources/HTTP_Source

### Kubernetes
Save the collector url (created above) as a secret in Kubernetes.

```
kubectl create secret generic sumologic --from-literal=collector-url=<INSERT_HTTP_URL>
```

And finally, you need to deploy the container. I will presume you have your own CI/CD setup. See the sample Kubernetes DaemonSet in [fluentd.daemonset.yaml](fluentd.daemonset.yaml)

```
kubectl create -f fluentd.daemonset.yaml
```

## Options

The following options can be configured as environment variables on the DaemonSet

* `FLUSH_INTERVAL` - How frequently to push logs to SumoLogic (default `5s`)
* `NUM_THREADS` - Increase number of http threads to Sumo. May be required in heavy logging clusters (default `1`)
* `SOURCE_NAME` - Set the `_sourceName` metadata field in SumoLogic. (Default `"%{namespace}.%{pod}.%{container}"`)
* `SOURCE_CATEGORY` - Set the `__sourceCategory` metadata field in SumoLogic. (Default `"%{namespace}/%{pod_name}"`)
* `SOURCE_CATEGORY_REPLACE_DASH` - Used to replace `-` with another character. (default `/`).
  * For example a Pod called `travel-nginx-3629474229-dirmo` within namespace `app` will show in SumoLogic with `_sourceCategory=app/travel/nginx`
* `LOG_FORMAT` - Format to post logs into Sumo. `json` or `text` (default `json`)
  * text - Logs will appear in SumoLogic in text format
  * json - Logs will appear in SumoLogic in json format.
  * json_merge - Same as json but if the container logs in json format to stdout it will merge in the container json log at the root level and remove the `log` field.
* `KUBERNETES_META` - Include or exclude Kubernetes metadata such as namespace and pod_name if using json log format. (default `true`)
* `READ_FROM_HEAD` - Start to read the logs from the head of file, not bottom. Only applies to containers log files. (default `true`). See [in_tail](http://docs.fluentd.org/v0.12/articles/in_tail#readfromhead) doc for more information.
* `EXCLUDE_PATH` - Files matching this pattern will be ignored by the in_tail plugin, and will not be sent to Kubernetes or Sumo Logic.  This can be a comma seperated list as well.  See [in_tail](http://docs.fluentd.org/v0.12/articles/in_tail#excludepath) doc for more information.
  * For example, setting EXCLUDE_PATH to the following would ignore all files matching /var/log/containers/*.log
```
...
        env:
        - name: EXCLUDE_PATH
          value: "[\"/var/log/containers/*.log\"]"
```
 * `EXCLUDE_NAMESPACE_REGEX` - A Regex pattern for namespaces.  All matching namespaces will be excluded from Sumo Logic.  The logs will still be sent to FluentD.
 * `EXCLUDE_POD_REGEX` - A Regex pattern for pods.  All matching pods will be excluded from Sumo Logic.  The logs will still be sent to FluentD.
 * `EXCLUDE_CONTAINER_REGEX` - A Regex pattern for containers.  All matching containers will be excluded from Sumo Logic.  The logs will still be sent to FluentD.
 * `EXCLUDE_HOST_REGEX` - A Regex pattern for hosts.  All matching hosts will be excluded from Sumo Logic.  The logs will still be sent to FluentD.

The following table show which  environment variables affect fluent sources

| Environment Variable | Containers | Docker | Kubernetes |
|----------------------|------------|--------|------------|
| `EXCLUDE_CONTAINER_REGEX` | ✔ | ✘ | ✘ |
| `EXCLUDE_HOST_REGEX `| ✔ | ✘ | ✘ |
| `EXCLUDE_NAMESPACE_REGEX` | ✔ | ✘ | ✔ |
| `EXCLUDE_PATH` | ✔ | ✔ | ✔ |
| `EXCLUDE_POD_REGEX` | ✔ | ✘ | ✘ |

The `LOG_FORMAT`, `SOURCE_CATEGORY` and `SOURCE_NAME` can be overridden per pod using [annotations](http://kubernetes.io/v1.0/docs/user-guide/annotations.html). For example

```
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    app: mywebsite
  template:
    metadata:
      name: nginx
      labels:
        app: mywebsite
      annotations:
        sumologic.com/format: "text"
        sumologic.com/sourceCategory: "mywebsite/nginx"
        sumologic.com/sourceName: "mywebsite_nginx"
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

## Excluding via annotation
You can also use the `sumologic.com/exclude` annotation to exclude data from Sumo Logic.  This data is still sent to FluentD, but will not make it to Sumo.

```
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    app: mywebsite
  template:
    metadata:
      name: nginx
      labels:
        app: mywebsite
      annotations:
        sumologic.com/format: "text"
        sumologic.com/sourceCategory: "mywebsite/nginx"
        sumologic.com/sourceName: "mywebsite_nginx"
        sumologic.com/exclude: "true"
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

## Logs, Yay
Simple as that really, your logs should be getting streamed to SumoLogic in json or text format with the appropriate metadata. If using `json` format you can auto extract fields, for example `_sourceCategory=some/app | json auto`

### Docker
![Docker Logs](/screenshots/docker.png)

### Kubelet
![Docker Logs](/screenshots/kubelet.png)

### Containers
![Docker Logs](/screenshots/container.png)
