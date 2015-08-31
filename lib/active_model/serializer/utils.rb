module ActiveModel::Serializer::Utils
  module_function

  # Translates a comma separated list of dot separated paths (JSON API format) into a Hash.
  #
  # @example
  #   `'posts.author, posts.comments.upvotes, posts.comments.author'`
  #
  #   would become
  #
  #   `{ posts: { author: {}, comments: { author: {}, upvotes: {} } } }`.
  #
  # @param [String] included
  # @return [Hash] a Hash representing the same tree structure
  def include_string_to_hash(included)
    included.delete(' ').split(',').inject({}) do |hash, path|
      hash.deep_merge!(path.split('.').reverse_each.inject({}) { |a, e| { e.to_sym => a } })
    end
  end

  # Translates the arguments passed to the include option into a Hash. The format can be either
  # a String (see #include_string_to_hash), an Array of Symbols and Hashes, or a mix of both.
  #
  # @example
  #  `posts: [:author, comments: [:author, :upvotes]]`
  #
  #  would become
  #
  #   `{ posts: { author: {}, comments: { author: {}, upvotes: {} } } }`.
  #
  # @example
  #  `[:author, :comments => [:author]]`
  #
  #   would become
  #
  #   `{:author => {}, :comments => { author: {} } }`
  #
  # @param [Symbol, Hash, Array, String] included
  # @return [Hash] a Hash representing the same tree structure
  def include_args_to_hash(included)
    case included
    when Symbol
      { included => {} }
    when Hash
      included.each_with_object({}) do |(key, value), hash|
        hash[key] = include_args_to_hash(value)
      end
    when Array
      included.inject({}) { |a, e| a.merge!(include_args_to_hash(e)) }
    when String
      include_string_to_hash(included)
    else
      {}
    end
  end
end
