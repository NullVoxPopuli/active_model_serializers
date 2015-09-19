module ActiveModel
  class Serializer
    class Adapter
      class Attributes < Adapter
        attr_accessor :_nested_associations

        def serializable_hash(options = nil)
          options ||= {}

          self._nested_associations = ActiveModel::Serializer::Utils
            .include_args_to_hash(options[:include])

          if serializer.respond_to?(:each)
            serializable_hash_for_collection(options)
          else
            serializable_hash_for_single_resource(options)
          end
        end

        def serializable_hash_for_collection(options = nil)
          serializer.map { |s| Attributes.new(s).serializable_hash(options) }
        end

        def serializable_hash_for_single_resource(options = {})
          resource = resource_object_for(serializer, options)
          add_resource_relationships(resource, serializer)
        end

        # iterate through the associations on the serializer,
        # adding them to the parent as needed (as singular or plural)
        #
        # nested_associations is a list of symbols that governs what
        # associations on the passed in seralizer to include
        def add_resource_relationships(parent, serializer)
          included_associations = relevant_included_associations_for(serializer, _nested_associations)

          included_associations.each do |association|
            serializer = association.serializer
            key = association.key
            opts = nested_options(key, association.options)
            # mutates parent
            add_relationship_for(parent, key, serializer, opts)
          end

          parent
        end

        def fragment_cache(cached_hash, non_cached_hash)
          Json::FragmentCache.new.fragment_cache(cached_hash, non_cached_hash)
        end

        private

        def nested_options(key, options)
          has_nesting = _nested_associations[key].present?
          if has_nesting
            include_options_from_parent = { include: _nested_associations[key] }
            options = options.merge(include_options_from_parent)
          end

          options
        end

        def relevant_included_associations_for(serializer, nested_associations = {})
          if nested_associations.present?
            serializer.associations.select do |association|
              # nested_associations is a hash of:
              #   key => nested association to include
              nested_associations.key?(association.name)
            end
          else
            serializer.associations
          end
        end

        def add_relationship_for(parent, key, serializer, opts)
          # mutates parent
          apply_relationship_to(parent, key) do
            if serializer.respond_to?(:each)
              to_many_relationship_for(serializer, opts)
            else
              to_one_relationship_for(serializer, opts)
            end
          end

          parent
        end

        def apply_relationship_to(hash, key)
          hash[key] = yield
        end

        # add a singular relationship
        # the options should always belong to the serializer
        def to_one_relationship_for(serializer, options)
          if options[:include].present?
            Attributes.new(serializer, options).serializable_hash(options)
          else
            serialized_or_virtual_of(serializer, options)
          end
        end

        # add a many relationship
        def to_many_relationship_for(serializer, options)
          serializer.map do |item_serializer|
            if options[:include].present?
              Attributes.new(item_serializer, options).serializable_hash(options)
            else
              resource_object_for(item_serializer, options)
            end
          end
        end

        # no-op: Attributes adapter does not include meta data, because it does not support root.
        def include_meta(json)
          json
        end

        # a virtual value is something that doesn't need a serializer,
        # such as a ruby array, or any other raw value
        def serialized_or_virtual_of(serializer, options)
          if options[:virtual_value]
            options[:virtual_value]
          elsif serializer && serializer.object
            resource_object_for(serializer, options)
          end
        end

        def resource_object_for(serializer, options)
          cache_check(serializer) do
            serializer.attributes(options)
          end
        end
      end
    end
  end
end
