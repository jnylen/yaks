# -*- coding: utf-8 -*-

module Yaks
  class Serializer
    class JsonApi < self
      Serializer.register self, :json_api, 'application/vnd.api+json'

      include FP

      def call
        serialized = {
          pluralize(resource.type) => resource.map(&method(:serialize_resource))
        }

        linked = resource.each_with_object({}) do |res, hsh|
          serialize_linked_subresources(res.subresources, hsh)
        end
        serialized = serialized.merge('linked' => linked)

        serialized
      end
      alias serialize call

      def serialize_resource(resource)
        result = resource.attributes
        result = result.merge(:links => serialize_links(resource.subresources)) unless resource.subresources.empty?
        result
      end

      def serialize_links(subresources)
        subresources.each_with_object({}) do |(name, resource), hsh|
          hsh[pluralize(resource.type)] = serialize_link(resource)
        end
      end

      def serialize_link(resource)
        resource.collection? ? resource.map(&send_with_args(:[], :id)) : resource[:id]
      end

      def serialize_linked_subresources(subresources, hsh)
        subresources.each_with_object(hsh) do |(name, resources), hsh|
          serialize_linked_resources(resources, hsh)
        end
      end

      def serialize_linked_resources(resources, linked)
        resources.each_with_object(linked) do |resource, memo|
          serialize_subresource(resource, memo)
        end
      end

      # {shows => [{id: 3, name: 'foo'}]}
      def serialize_subresource(resource, linked)
        key = pluralize(resource.type)
        set = linked.fetch(key) { Set.new }
        linked = linked[key] = (set << serialize_resource(resource))
        serialize_linked_subresources(resource.subresources, linked)
      end
    end
  end
end