require "fluent/plugin/parser"
require 'google/protobuf'
require 'base64'
require 'snappy'
require_relative 'types_pb'
require_relative 'remote_pb'

module Fluent::Plugin
  class ProtobufParser < Fluent::Plugin::Parser
    Fluent::Plugin.register_parser("protobuf", self)
    def configure(conf)
      super
    end

    def parse(text)
      begin
        inflated = Snappy.inflate(text)
        # encoded = Base64.encode64(inflated)
        # log.info("HIT PARSER: #{encoded}")

        decoded = Prometheus::WriteRequest.decode(inflated)
        # only retain the first ts' first sample
        ts = decoded.timeseries[0]
        # sample = ts.samples[0]
        log.info(ts)
        yield nil, ts
      rescue => e
        log.error("ERROR during decoding: #{e.message}")
        yield nil, nil
      end
    end
  end
end