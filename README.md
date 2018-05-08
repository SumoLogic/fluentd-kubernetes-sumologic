This page describes the Sumo Kubernetes [Fluentd](http://www.fluentd.org/) plugin.

## Support
The code in this repository has been contributed by the Sumo Logic community and is not officially supported by Sumo Logic. For any issues or questions please submit an issue through GitHub or start a conversation within the [Sumo Logic Community](https://community.sumologic.com) forums.  The maintainers of this project will work directly with the community to answer any questions, address bugs, or review any requests for new features. 

## Installation

The plugin runs as a Kubernetes [DaemonSet](http://kubernetes.io/docs/admin/daemons/); it runs an instance of the plugin on each host in a cluster. Each plugin instance pulls system, kubelet, docker daemon, and container logs from the host and sends them, in JSON or text format, to an HTTP endpoint on a hosted collector in the [Sumo](http://www.sumologic.com) service.

- [Step 1  Create hosted collector and HTTP source in Sumo](#step-1--create-hosted-collector-and-http-source-in-sumo)
- [Step 2  Create a Kubernetes secret](#step-2--create-a-kubernetes-secret)
- [Step 3  Install the Sumo Kubernetes FluentD plugin](#step-3--install-the-sumo-kubernetes-fluentd-plugin)
  * [Option A  Install plugin using kubectl](#option-a--install-plugin-using-kubectl)
  * [Option B  Helm chart](#option-b--helm-chart)
- [Environment variables](#environment-variables)
    + [Override environment variables using annotations](#override-environment-variables-using-annotations)
    + [Exclude data using annotations](#exclude-data-using-annotations)
    + [Include excluded using annotations](#include-excluded-using-annotations)
- [Step 4 Set up Heapster for metric collection](#step-4-set-up-heapster-for-metric-collection)
  * [Kubernetes ConfigMap](#kubernetes-configmap)
  * [Kubernetes Service](#kubernetes-service)
  * [Kubernetes Deployment](#kubernetes-deployment)
- [Log data](#log-data)
  * [Docker](#docker)
  * [Kubelet](#kubelet)
  * [Containers](#containers)
- [Taints and Tolerations](#taints-and-tolerations)



![deployment](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/blob/master/screenshots/kubernetes.png)

# Step 1  Create hosted collector and HTTP source in Sumo

In this step you create, on the Sumo service, an HTTP endpoint to receive your logs. This process involves creating an HTTP source on a hosted collector in Sumo. In Sumo, collectors use sources to receive data.

1. If you don’t already have a Sumo account, you can create one by clicking the **Free Trial** button on https://www.sumologic.com/.
2. Create a hosted collector, following the instructions on [Configure a Hosted Collector](https://help.sumologic.com/Send-Data/Hosted-Collectors/Configure-a-Hosted-Collector) in Sumo help. (If you already have a Sumo hosted collector that you want to use, skip this step.)  
3. Create an HTTP source on the collector you created in the previous step. For instructions, see [HTTP Logs and Metrics Source](https://help.sumologic.com/Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source) in Sumo help. 
4. When you have configured the HTTP source, Sumo will display the URL of the HTTP endpoint. Make a note of the URL. You will use it when you configure the Kubernetes service to send data to Sumo. 

# Step 2  Create a Kubernetes secret

Create a secret in Kubernetes with the HTTP source URL. If you want to change the secret name, you must modify the Kubernetes manifest accordingly.

`kubectl create secret generic sumologic --from-literal=collector-url=INSERT_HTTP_URL`

You should see the confirmation message 

`secret "sumologic" created.`

# Step 3  Install the Sumo Kubernetes FluentD plugin

Follow the instructions in Option A below to install the plugin using `kubectl`. If you prefer to use a Helm chart, see Option B. 

Before you start, see [Environment variables](#environment-variables) for information about settings you can customize, and how to use annotations to override selected environment variables and exclude data from being sent to Sumo.

## Option A  Install plugin using kubectl

See the sample Kubernetes DaemonSet and Role in [fluentd.yaml](/daemonset/rbac/fluentd.yaml).

1. Clone the [GitHub repo](https://github.com/SumoLogic/fluentd-kubernetes-sumologic).

2. In `fluentd-kubernetes-sumologic`, install the chart using `kubectl`.

Which `.yaml` file you should use depends on whether or not you are running RBAC for authorization. RBAC is enabled by default as of Kubernetes 1.6.

**Non-RBAC (Kubernetes 1.5 and below)** 

`kubectl create -f /daemonset/nonrbac/fluentd.yaml` 

**RBAC (Kubernetes 1.6 and above)** <br/><br/>`kubectl create -f /daemonset/rbac/fluentd.yaml`


**Note** if you modified the command in Step 2 to use a different name, update the `.yaml` file to use the correct secret.

Logs should begin flowing into Sumo within a few minutes of plugin installation.

## Option B  Helm chart
If you use Helm to manage your Kubernetes resources, there is a Helm chart for the plugin at https://github.com/kubernetes/charts/tree/master/stable/sumologic-fluentd.

# Environment variables

Environment | Variable Description
----------- | --------------------
`AUDIT_LOG_PATH`|Define the path to the [Kubernetes Audit Log](https://kubernetes.io/docs/tasks/debug-application-cluster/audit/) <br/><br/> Default: `/mnt/log/kube-apiserver-audit.log`
`CONCAT_SEPARATOR` |The character to use to delimit lines within the final concatenated message. Most multi-line messages contain a newline at the end of each line. <br/><br/> Default: ""
`EXCLUDE_CONTAINER_REGEX` |A regular expression for containers. Matching containers will be excluded from Sumo. The logs will still be sent to FluentD.
`EXCLUDE_FACILITY_REGEX`|A regular expression for syslog [facilities](https://en.wikipedia.org/wiki/Syslog#Facility). Matching facilities will be excluded from Sumo. The logs will still be sent to FluentD.
`EXCLUDE_HOST_REGEX`|A regular expression for hosts. Matching hosts will be excluded from Sumo. The logs will still be sent to FluentD.
`EXCLUDE_NAMESPACE_REGEX`|A regular expression for `namespaces`. Matching `namespaces` will be excluded from Sumo. The logs will still be sent to FluentD.
`EXCLUDE_PATH`|Files matching this pattern will be ignored by the `in_tail` plugin, and will not be sent to Kubernetes or Sumo. This can be a comma-separated list as well. See [in_tail](http://docs.fluentd.org/v0.12/articles/in_tail#excludepath) documentation for more information. <br/><br/> For example, defining `EXCLUDE_PATH` as shown below excludes all files matching `/var/log/containers/*.log`, <br/><br/>`...`<br/><br/>`env:`<br/>   - `name: EXCLUDE_PATH`<br/>         `value: "[\"/var/log/containers/*.log\"]"`
`EXCLUDE_POD_REGEX`|A regular expression for pods. Matching pods will be excluded from Sumo. The logs will still be sent to FluentD.
`EXCLUDE_PRIORITY_REGEX`|A regular expression for syslog [priorities](https://en.wikipedia.org/wiki/Syslog#Severity_level). Matching priorities will be excluded from Sumo. The logs will still be sent to FluentD.
`EXCLUDE_UNIT_REGEX` |A regular expression for `systemd` units. Matching units will be excluded from Sumo. The logs will still be sent to FluentD.
`FLUENTD_SOURCE`|Fluentd can tail files or query `systemd`. Allowable values: `file`, `Systemd`. <br/><br/>Default: `file` 
`FLUENTD_USER_CONFIG_DIR`|A directory of user-defined fluentd configuration files, which must be in the  `*.conf` directory in the container.
`FLUSH_INTERVAL` |How frequently to push logs to Sumo.<br/><br/>Default: `5s`
`KUBERNETES_META`|Include or exclude Kubernetes metadata such as `namespace` and `pod_name` if using JSON log format. <br/><br/>Default: `true`
`LOG_FORMAT`|Format in which to post logs to Sumo. Allowable values:<br/><br/>`text`—Logs will appear in SumoLogic in text format.<br/>`json`—Logs will appear in SumoLogic in json format.<br/>`json_merge`—Same as json but if the container logs in json format to stdout it will merge in the container json log at the root level and remove the log field.<br/><br/>Default: `json`
`MULTILINE_START_REGEXP`|The regular expression for the `concat` plugin to use when merging multi-line messages. Defaults to Julian dates, for example, Jul 29, 2017.
`NUM_THREADS`|Set the number of HTTP threads to Sumo. It might be necessary to do so in heavy-logging clusters. <br/><br/>Default: `1`
`READ_FROM_HEAD`|Start to read the logs from the head of file, not bottom. Only applies to containers log files. See in_tail doc for more information.<br/><br/>Default: `true` 
`SOURCE_CATEGORY` |Set the `_sourceCategory` metadata field in Sumo. <br/><br/>Default: `"%{namespace}/%{pod_name}"`
`SOURCE_CATEGORY_PREFIX`|Prepends a string that identifies the cluster to the `_sourceCategory` metadata field in Sumo.<br/><br/>Default:  `kubernetes/`
`SOURCE_CATEGORY_REPLACE_DASH` |Used to replace a dash (-) character with another character. <br/><br/>Default:  `/`<br/><br/>For example, a Pod called `travel-nginx-3629474229-dirmo` within namespace `app` will appear in Sumo with `_sourceCategory=app/travel/nginx`.
`SOURCE_HOST`|Set the `_sourceHost` metadata field in Sumo.<br/><br/>Default: `""`
`SOURCE_NAME`|Set the `_sourceName` metadata field in Sumo. <br/><br/> Default: `"%{namespace}.%{pod}.%{container}"`
`TIME_KEY`|The field name for json formatted sources that should be used as the time. See [time_key](https://docs.fluentd.org/v0.12/articles/formatter_json#time_key-(string,-optional,-defaults-to-%E2%80%9Ctime%E2%80%9D)). Default: `time`
`ADD_TIMESTAMP`|Option to control adding timestamp to logs. Default: `true`

The following table show which  environment variables affect which Fluentd sources.

| Environment Variable | Containers | Docker | Kubernetes | Systemd |
|----------------------|------------|--------|------------|---------|
| `EXCLUDE_CONTAINER_REGEX` | ✔ | ✘ | ✘ | ✘ |
| `EXCLUDE_FACILITY_REGEX` | ✘ | ✘ | ✘ | ✔ |
| `EXCLUDE_HOST_REGEX `| ✔ | ✘ | ✘ | ✔ |
| `EXCLUDE_NAMESPACE_REGEX` | ✔ | ✘ | ✔ | ✘ |
| `EXCLUDE_PATH` | ✔ | ✔ | ✔ | ✘ |
| `EXCLUDE_PRIORITY_REGEX` | ✘ | ✘ | ✘ | ✔ |
| `EXCLUDE_POD_REGEX` | ✔ | ✘ | ✘ | ✘ |
| `EXCLUDE_UNIT_REGEX` | ✘ | ✘ | ✘ | ✔ |
| `TIME_KEY` | ✔ | ✘ | ✘ | ✘ |

### Override environment variables using annotations
You can override the `LOG_FORMAT`, `SOURCE_CATEGORY` and `SOURCE_NAME` environment variables, per pod, using [Kubernetes annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/). For example:

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

### Exclude data using annotations

You can also use the `sumologic.com/exclude` annotation to exclude data from Sumo. This data is sent to FluentD, but not to Sumo.

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

### Include excluded using annotations

If you excluded a whole namespace, but still need one or few pods to be still included for shipping to Sumologic, you can use the `sumologic.com/include` annotation to include data to Sumo. It takes precedence over the exclusion described above.

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
        sumologic.com/include: "true"
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

# Step 4 Set up Heapster for metric collection

The recommended way to collect metrics from Kubernetes clusters is to use Heapster and a Sumo collector with a Graphite source. 

Heapster aggregates metrics across a Kubenetes cluster. Heapster runs as a pod in the cluster, and  discovers all nodes in the cluster and queries usage information from each node's `kubelet`—the on-machine Kubernetes agent. 

Heapster provides metrics at the cluster, node and pod level.

1. Install Heapster in your Kubernetes cluster and configure a Graphite Sink to send the data in Graphite format to Sumo. For instructions, see 
https://github.com/kubernetes/heapster/blob/master/docs/sink-configuration.md#graphitecarbon. Assuming you have used the below YAML files to configure your system, then the sink option in graphite would be `--sink=graphite:tcp://sumo-graphite.kube-system.svc:2003`.  You may need to change this depending on the namespace you run the deployment in, the name of the service or the port number for your Graphite source.

2. Use the Sumo Docker container. For instructions, see https://hub.docker.com/r/sumologic/collector/.

3. The following sections contain an  example configmap, which contains the `sources.json` configuration, an example service, and an example deployment. Create these manifests in Kubernetes using `kubectl`.


## Kubernetes ConfigMap
```
kind: ConfigMap
apiVersion: v1
metadata:
  name: "sumo-sources"
data:
  sources.json: |-
    {
      "api.version": "v1",
      "sources": [
        {
          "name": "SOURCE_NAME",
          "category": "SOURCE_CATEGORY",
          "automaticDateParsing": true,
          "contentType": "Graphite",
          "timeZone": "UTC",
          "encoding": "UTF-8",
          "protocol": "TCP",
          "port": 2003,
          "sourceType": "Graphite"
        }
      ]
    }

```
## Kubernetes Service
```
apiVersion: v1
kind: Service
metadata:
  name: sumo-graphite
spec:
  ports:
    - port: 2003
  selector:
    app: sumo-graphite
```
## Kubernetes Deployment
```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: sumo-graphite
  name: sumo-graphite
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: sumo-graphite
    spec:
      volumes:
      - name: sumo-sources
        configMap:
          name: sumo-sources
          items:
          - key: sources.json
            path: sources.json
      containers:
      - name: sumo-graphite
        image: sumologic/collector:latest
        ports:
        - containerPort: 2003
        volumeMounts:
        - mountPath: /sumo
          name: sumo-sources
        env:
        - name: SUMO_ACCESS_ID
          value: <SUMO_ACCESS_ID>
        - name: SUMO_ACCESS_KEY
          value: <SUMO_ACCESS_KEY>
        - name: SUMO_SOURCES_JSON
          value: /sumo/sources.json

```

# Log data
After performing the configuration described above, your logs should start streaming to SumoLogic in `json` or text format with the appropriate metadata. If you are using `json` format you can auto extract fields, for example `_sourceCategory=some/app | json auto`.

## Docker
![Docker Logs](/screenshots/docker.png)

## Kubelet
Note that Kubelet logs are only collected if you are using systemd.  Kubernetes no longer outputs the kubelet logs to a file.
![Docker Logs](/screenshots/kubelet.png)

## Containers
![Docker Logs](/screenshots/container.png)

# Taints and Tolerations
By default, the fluentd pods will schedule on, and therefore collect logs from, any worker nodes that do not have a taint and any master node that does not have a taint beyond the default master taint. If you would like to schedule pods on all nodes, regardless of taints, uncomment the following line from fluentd.yaml before applying it.

```
tolerations:
           #- operator: "Exists"
```
