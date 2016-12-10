require 'fluent/filter'

module Fluent
  class SumoContainerOutput < Filter
    # Register type
    Fluent::Plugin.register_filter('kubernetes_sumologic', self)

    config_param :kubernetes_meta, :bool, :default => true
    config_param :source_category, :string, :default => '%{namespace}/%{pod_name}'
    config_param :source_category_replace_dash, :string, :default => '/'
    config_param :source_category_prefix, :string, :default => 'kubernetes/'
    config_param :source_name, :string, :default => '%{namespace}.%{pod}.%{container}'

    def configure(conf)
      super
    end

    def is_number?(string)
      true if Float(string) rescue false
    end

    def filter(tag, time, record)
      unless record.fetch('kubernetes').nil?

        # Clone kubernetes hash so we don't override the cache
        kubernetes = record['kubernetes'].clone

        metadata = {
            :namespace => kubernetes['namespace_name'],
            :pod => kubernetes['pod_name'],
            :container => kubernetes['container_name'],
            :source_host => kubernetes['host'],
        }

        # Strip out dynamic bits from pod name.
        # NOTE: Kubernetes deployments append a template hash.
        pod_parts = metadata[:pod].split('-')
        if is_number?(pod_parts[-2])
          metadata[:pod_name] = pod_parts[0..-3].join('-')
        else
          metadata[:pod_name] = pod_parts[0..-2].join('-')
        end

        annotations = kubernetes.fetch('annotations', {})

        sumo_metadata = record[:_sumo_metadata] = {}
        sumo_metadata[:host] = metadata[:source_host]
        sumo_metadata[:source] = (annotations['sumologic.com/sourceName'] || @source_name) % metadata
        sumo_metadata[:category] = ((annotations['sumologic.com/sourceCategory'] || @source_category) % metadata).prepend(@source_category_prefix)
        sumo_metadata[:category].gsub!('-', @source_category_replace_dash)
        sumo_metadata[:log_format] = annotations['sumologic.com/format']

        # Strip kubernetes metadata from json if disabled
        if annotations['sumologic.com/kubernetes_meta'] == 'false' || !@kubernetes_meta
          record.delete('docker')
          record.delete('kubernetes')
        end

        # Strip sumologic.com annotations
        kubernetes.delete('annotations') if annotations

      end

      record
    end
  end
end