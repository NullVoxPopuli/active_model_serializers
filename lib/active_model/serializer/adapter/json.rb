module ActiveModel
  class Serializer
    class Adapter
      class Json < Adapter
        extend ActiveSupport::Autoload
        autoload :FragmentCache

        def serializable_hash(options = nil)
          options ||= {}
          { root => Attributes.new(serializer).serializable_hash(options) }
        end
      end
    end
  end
end
