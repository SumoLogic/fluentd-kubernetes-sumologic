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
    config_param :source_host, :string, :default => ''

    config_param :exclude_container_regex, :string, :default => ''
    config_param :exclude_facility_regex, :string, :default => ''
    config_param :exclude_host_regex, :string, :default => ''
    config_param :exclude_namespace_regex, :string, :default => ''
    config_param :exclude_pod_regex, :string, :default => ''
    config_param :exclude_priority_regex, :string, :default => ''
    config_param :exclude_unit_regex, :string, :default => ''

    def configure(conf)
      super
    end

    def is_number?(string)
      true if Float(string) rescue false
    end

    def filter(tag, time, record)
      # Set the sumo metadata fields
      sumo_metadata = record['_sumo_metadata'] || {}
      record['_sumo_metadata'] = sumo_metadata

      sumo_metadata[:log_format] = @log_format
      sumo_metadata[:host] = @source_host if @source_host
      sumo_metadata[:source] = @source_name if @source_name

      unless @source_category.nil?
        sumo_metadata[:category] = @source_category.dup
        unless @source_category_prefix.nil?
          sumo_metadata[:category].prepend(@source_category_prefix)
        end
      end

      if record.key?('_SYSTEMD_UNIT') and not record.fetch('_SYSTEMD_UNIT').nil?
        unless @exclude_unit_regex.empty?
          if Regexp.compile(@exclude_unit_regex).match(record['_SYSTEMD_UNIT'])
            return nil
          end
        end

        unless @exclude_facility_regex.empty?
          if Regexp.compile(@exclude_facility_regex).match(record['SYSLOG_FACILITY'])
            return nil
          end
        end

        unless @exclude_priority_regex.empty?
          if Regexp.compile(@exclude_priority_regex).match(record['PRIORITY'])
            return nil
          end
        end

        unless @exclude_host_regex.empty?
          if Regexp.compile(@exclude_host_regex).match(record['_HOSTNAME'])
            return nil
          end
        end

      end

      # Allow fields to be overridden by annotations
      if record.key?('kubernetes') and not record.fetch('kubernetes').nil?
        # Clone kubernetes hash so we don't override the cache
        kubernetes = record['kubernetes'].clone
        k8s_metadata = {
            :namespace => kubernetes['namespace_name'],
            :pod => kubernetes['pod_name'],
            :container => kubernetes['container_name'],
            :source_host => kubernetes['host'],
        }

        annotations = kubernetes.fetch('annotations', {})

        if annotations['sumologic.com/include'] == 'true'
          include = true
        else
          include = false
        end
        
        unless @exclude_namespace_regex.empty?
          if Regexp.compile(@exclude_namespace_regex).match(k8s_metadata[:namespace]) and not include
            return nil
          end
        end

        unless @exclude_pod_regex.empty?
          if Regexp.compile(@exclude_pod_regex).match(k8s_metadata[:pod]) and not include
            return nil
          end
        end

        unless @exclude_container_regex.empty?
          if Regexp.compile(@exclude_container_regex).match(k8s_metadata[:container]) and not include
            return nil
          end
        end

        unless @exclude_host_regex.empty?
          if Regexp.compile(@exclude_host_regex).match(k8s_metadata[:source_host]) and not include
            return nil
          end
        end

        # Strip out dynamic bits from pod name.
        # NOTE: Kubernetes deployments append a template hash.
        pod_parts = k8s_metadata[:pod].split('-')
        if is_number?(pod_parts[-2])
          k8s_metadata[:pod_name] = pod_parts[0..-3].join('-')
        else
          k8s_metadata[:pod_name] = pod_parts[0..-2].join('-')
        end

        if annotations['sumologic.com/exclude'] == 'true'
          return nil
        end

        sumo_metadata[:log_format] = annotations['sumologic.com/format'] if annotations['sumologic.com/format']

        if annotations['sumologic.com/sourceHost'].nil?
          sumo_metadata[:host] = sumo_metadata[:host] % k8s_metadata
        else
          sumo_metadata[:host] = annotations['sumologic.com/sourceHost'] % k8s_metadata
        end

        if annotations['sumologic.com/sourceName'].nil?
          sumo_metadata[:source] = sumo_metadata[:source] % k8s_metadata
        else
          sumo_metadata[:source] = annotations['sumologic.com/sourceName'] % k8s_metadata
        end

        if annotations['sumologic.com/sourceCategory'].nil?
          sumo_metadata[:category] = sumo_metadata[:category] % k8s_metadata
        else
          sumo_metadata[:category] = (annotations['sumologic.com/sourceCategory'] % k8s_metadata).prepend(@source_category_prefix)
        end
        sumo_metadata[:category].gsub!('-', @source_category_replace_dash)

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
