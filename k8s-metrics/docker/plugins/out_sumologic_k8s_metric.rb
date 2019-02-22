require "fluent/plugin/output"

module Fluent::Plugin
  class SumologicK8sMetricOutput < Fluent::Plugin::Output
    Fluent::Plugin.register_output("sumologic_k8s_metric", self)

    helpers :event_emitter, :record_accessor

    def configure(conf)
      super
      # do the usual configuration here
      @timestamp = record_accessor_create('$.@timestamp')
    end
    
    def multi_workers_ready?
      true
    end
  
    def process(tag, es)
      es.each do |time, record|
        case tag
        when "prometheus.metrics"
          log.trace("sumologic_k8s_metric::metricset.kubernetes.pod: tag=#{tag}, time=#{time}, record=#{record}", record)
          write_metric(time, record)
        # when "metricset.kubernetes.node"
          
        else
          log.trace("sumologic_k8s_metric: tag #{tag} is not parsed", record)
        end
      end
    end

    private

    def write_metric(time, record)
      intrinsic_tags = Hash.new
      sample = record.samples[0]
      parsed_time = sample.timestamp
      value = sample.value

      labels = record.labels
      metric_name = labels[0].value
      labels.each do |label|
        unless (label.name == '__name__')
          intrinsic_tags[label.name] = label.value
        end
      end

      tag_part = "#{hash_to_string(intrinsic_tags)}"

      if (value)
        metric_str = "metric=#{metric_name} #{tag_part}  #{value} #{parsed_time}"
        log.info(metric_str)
        new_tag = 'carbon.v2.prometheus.metrics'
        write_to_pipeline(new_tag, parsed_time, metric_str)
      end

    end


    def write_pod_set(time, record)
      intrinsic_tags = Hash.new
      metadata_tags = Hash.new
      
      append_entry(record, '$.kubernetes.namespace', intrinsic_tags, 'kubernetes.namespace')
      append_entry(record, '$.kubernetes.node.name', intrinsic_tags, 'kubernetes.node.name')
      append_entry(record, '$.kubernetes.pod.name', intrinsic_tags, 'kubernetes.pod.name')
      append_entry(record, '$.kubernetes.pod.uid', intrinsic_tags, 'kubernetes.pod.uid')
      append_entry(record, '$.host.name', intrinsic_tags, 'host.name')
      append_entry(record, '$.meta.cloud.instance_id', intrinsic_tags, 'cloud.instance_id')
      append_entry(record, '$.meta.cloud.machine_type', intrinsic_tags, 'cloud.machine_type')
      append_entry(record, '$.meta.cloud.region', intrinsic_tags, 'cloud.region')
      append_entry(record, '$.meta.cloud.availability_zone', intrinsic_tags, 'cloud.availability_zone')
      append_entry(record, '$.meta.cloud.provider', intrinsic_tags, 'cloud.provider')
      append_labels(record, '$.kubernetes.labels', metadata_tags, 'kubernetes.labels')

      tag_part = "#{hash_to_string(intrinsic_tags)}  #{hash_to_string(metadata_tags)}"

      label_keys = {
        '$.kubernetes.pod.cpu.usage.nanocores' => 'kubernetes.pod.cpu.usage.nanocores', 
        '$.kubernetes.pod.cpu.usage.node.pct' => 'kubernetes.pod.cpu.usage.node.percentage',
        '$.kubernetes.pod.cpu.usage.limit.pct' => 'kubernetes.pod.cpu.usage.limit.percentage',
        '$.kubernetes.pod.memory.usage.bytes' => 'kubernetes.pod.memory.usage.bytes',
        '$.kubernetes.pod.memory.usage.node.pct' => 'kubernetes.pod.memory.usage.node.percentage',
        '$.kubernetes.pod.memory.usage.limit.pct' => 'kubernetes.pod.memory.usage.limit.percentage',
        '$.kubernetes.pod.network.rx.bytes' => 'kubernetes.pod.network.rx.bytes',
        '$.kubernetes.pod.network.rx.errors' => 'kubernetes.pod.network.rx.errors',
        '$.kubernetes.pod.network.tx.bytes' => 'kubernetes.pod.network.tx.bytes',
        '$.kubernetes.pod.network.tx.errors' => 'kubernetes.pod.network.tx.errors'
      }

      time_in_json = Time.parse(@timestamp.call(record))

      message = label_keys.flat_map { |accessor_key, metric_key|
        accessor = record_accessor_create(accessor_key)
        value = accessor.call(record).to_f
        "metric=#{metric_key} #{tag_part} #{value} #{time_in_json.to_i}"
      }.join($/)

      tag = 'carbon.v2.prometheus.metrics'

      write_to_pipeline(tag, time_in_json, message)

    end
    
    def append_entry(record, accessor_key, hash, target_key)
      accessor = record_accessor_create(accessor_key)
      hash[target_key] = accessor.call(record).to_s
    end

    def append_labels(record, labels_accessor_key, hash, labels_target_key)
      accessor = record_accessor_create(labels_accessor_key)
      labels = accessor.call(record)
      labels.flat_map { |key, value|
        hash["#{labels_target_key}.#{key}"] = value
      }
    end
    
    def hash_to_string(hash)
      if (hash.is_a?(Hash) && !hash.empty?)
        hash.flat_map { |key, value|
          "#{key}=#{value}"
        }.join(" ")
      else
        ""
      end
    end

    def write_to_pipeline(tag, time, message)
      record = Hash.new
      record['message'] = message
      router.emit(tag, time, record)
    end

  end
end