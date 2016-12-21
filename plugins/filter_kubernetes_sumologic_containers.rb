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
    config_param :log_format, :string, :default => 'json'
    config_param :source_host, :string, :default => nil

    def configure(conf)
      super
    end

    def is_number?(string)
      true if Float(string) rescue false
    end

    def filter(tag, time, record)
      # Set the sumo metadata fields
      sumo_metadata = record[:_sumo_metadata] = {}
      sumo_metadata[:log_format] = @log_format
      sumo_metadata[:host] = metadata[:source_host] if @source_host
      sumo_metadata[:source] = @source_name if @source_name

      unless @source_category.nil?
        sumo_metadata[:category] = @source_category.prepend(@source_category_prefix)
      end

      # Allow fields to be overridden by annotations
      unless record.fetch('kubernetes').nil?
        # Clone kubernetes hash so we don't override the cache
        kubernetes = record['kubernetes'].clone
        k8s_metadata = {
            :namespace => kubernetes['namespace_name'],
            :pod => kubernetes['pod_name'],
            :container => kubernetes['container_name'],
            :source_host => kubernetes['host'],
        }

        # Strip out dynamic bits from pod name.
        # NOTE: Kubernetes deployments append a template hash.
        pod_parts = metadata[:pod].split('-')
        if is_number?(pod_parts[-2])
          k8s_metadata[:pod_name] = pod_parts[0..-3].join('-')
        else
          k8s_metadata[:pod_name] = pod_parts[0..-2].join('-')
        end

        annotations = kubernetes.fetch('annotations', {})

        sumo_metadata[:log_format] = annotations['sumologic.com/format'] if annotations['sumologic.com/format']
        sumo_metadata[:host] = k8s_metadata[:source_host]
        sumo_metadata[:source] = annotations['sumologic.com/sourceName'] % k8s_metadata if annotations['sumologic.com/sourceName']

        if annotations['sumologic.com/sourceCategory'].nil?
          sumo_metadata[:category] = annotations['sumologic.com/sourceCategory'] % k8s_metadata.prepend(@source_category_prefix)
          sumo_metadata[:category].gsub!('-', @source_category_replace_dash)
        end

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