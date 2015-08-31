module ActiveModel
  class Serializer
    module Utils
      class UtilsTest < MiniTest::Test
        def test_include_args_to_hash_from_symbol
          expected = { author: {} }
          input = :author
          actual = ActiveModel::Serializer::Utils.include_args_to_hash(input)

          assert_equal(expected, actual)
        end

        def test_include_args_to_hash_from_array
          expected = { author: {}, comments: {} }
          input = [:author, :comments]
          actual = ActiveModel::Serializer::Utils.include_args_to_hash(input)

          assert_equal(expected, actual)
        end

        def test_include_args_to_hash_from_nested_array
          expected = { author: {}, comments: { author: {} } }
          input = [:author, comments: [:author]]
          actual = ActiveModel::Serializer::Utils.include_args_to_hash(input)

          assert_equal(expected, actual)
        end

        def test_include_args_to_hash_from_array_of_hashes
          expected = {
            author: {},
            blogs: { posts: { contributors: {} } },
            comments: { author: { blogs: { posts: {} } } }
          }
          input = [
            :author,
            blogs: [posts: :contributors],
            comments: { author: { blogs: :posts } }
          ]
          actual = ActiveModel::Serializer::Utils.include_args_to_hash(input)

          assert_equal(expected, actual)
        end
      end
    end
  end
end
