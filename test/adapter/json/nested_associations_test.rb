require 'test_helper'

module ActiveModel
  class Serializer
    class Adapter
      class Json
        class NestedAssociationsTest < Minitest::Test
          class NestedPostSerializer < ActiveModel::Serializer
            attributes :id, :title

            has_many :comments, include: :author
          end

          class NestedCommentBelongsToSerializer < ActiveModel::Serializer
            attributes :id, :body

            belongs_to :author, include: [:posts]
          end

          class NestedAuthorSerializer < ActiveModel::Serializer
            attributes :id, :name

            has_many :posts, include: [:comments]
          end

          class ComplexNestedAuthorSerializer < ActiveModel::Serializer
            attributes :id, :name

            # it would normally be silly to have this in production code, cause a post's
            # author in this case is always going to be your root object
            has_many :posts, include: [:author, comments: [:author]]
          end

          class MultipleRelationshipAuthorSerializer < ActiveModel::Serializer
            attributes :id, :name

            has_many :posts, include: [{ comments: [:author] }]
            has_many :comments
          end

          def setup
            ActionController::Base.cache_store.clear
            @author = Author.new(id: 1, name: 'Steve K.')

            @post = Post.new(id: 42, title: 'New Post', body: 'Body')
            @first_comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
            @second_comment = Comment.new(id: 2, body: 'ZOMG ANOTHER COMMENT')

            @post.comments = [@first_comment, @second_comment]
            @post.author = @author

            @first_comment.post = @post
            @second_comment.post = @post

            @blog = Blog.new(id: 1, name: 'My Blog!!')
            @post.blog = @blog
            @author.posts = [@post]
          end

          def test_multiple_relationships_has_many
            @first_comment.author = @author
            @second_comment.author = @author
            @author.comments = [@first_comment, @second_comment]

            serializable = SerializableResource.new(
              @author,
              serializer: MultipleRelationshipAuthorSerializer,
              adapter: :json)

            expected = {
              author: {
                id: 1,
                name: 'Steve K.',
                posts: [
                  {
                    id: 42, title: 'New Post', body: 'Body',
                    comments: [
                      {
                        id: 1, body: 'ZOMG A COMMENT',
                        author: {
                          id: 1,
                          name: 'Steve K.'
                        }
                      },
                      {
                        id: 2, body: 'ZOMG ANOTHER COMMENT',
                        author: {
                          id: 1,
                          name: 'Steve K.'
                        }
                      }
                    ]
                  }
                ],
                comments: [
                  {
                    id: 1, body: 'ZOMG A COMMENT'
                  },
                  {
                    id: 2, body: 'ZOMG ANOTHER COMMENT'
                  }
                ]
              }
            }

            actual = serializable.serializable_hash

            assert_equal(expected, actual)
          end

          def test_complex_nested_has_many
            @first_comment.author = @author
            @second_comment.author = @author

            serializable = SerializableResource.new(
              @author,
              serializer: ComplexNestedAuthorSerializer,
              adapter: :json)

            expected = {
              author: {
                id: 1,
                name: 'Steve K.',
                posts: [
                  {
                    id: 42, title: 'New Post', body: 'Body',
                    author: {
                      id: 1,
                      name: 'Steve K.'
                    },
                    comments: [
                      {
                        id: 1, body: 'ZOMG A COMMENT',
                        author: {
                          id: 1,
                          name: 'Steve K.'
                        }
                      },
                      {
                        id: 2, body: 'ZOMG ANOTHER COMMENT',
                        author: {
                          id: 1,
                          name: 'Steve K.'
                        }
                      }
                    ]
                  }
                ]
              }
            }

            actual = serializable.serializable_hash

            assert_equal(expected, actual)
          end

          def test_nested_has_many
            serializable = SerializableResource.new(
              @author,
              serializer: NestedAuthorSerializer,
              adapter: :json)

            expected = {
              author: {
                id: 1,
                name: 'Steve K.',
                posts: [
                  {
                    id: 42, title: 'New Post', body: 'Body',
                    comments: [
                      {
                        id: 1, body: 'ZOMG A COMMENT'
                      },
                      {
                        id: 2, body: 'ZOMG ANOTHER COMMENT'
                      }
                    ]
                  }
                ]
              }
            }

            actual = serializable.serializable_hash

            assert_equal(expected, actual)
          end

          def test_belongs_to_on_a_has_many
            @first_comment.author = @author
            @second_comment.author = @author

            serializable = SerializableResource.new(
              @post,
              serializer: NestedPostSerializer,
              adapter: :json)

            expected = {
              post: {
                id: 42, title: 'New Post',
                comments: [
                  {
                    id: 1, body: 'ZOMG A COMMENT',
                    author: {
                      id: 1,
                      name: 'Steve K.'
                    }
                  },
                  {
                    id: 2, body: 'ZOMG ANOTHER COMMENT',
                    author: {
                      id: 1,
                      name: 'Steve K.'
                    }
                  }
                ]
              }
            }

            actual = serializable.serializable_hash

            assert_equal(expected, actual)
          end

          def test_belongs_to_with_a_has_many
            @author.roles = []
            @author.bio = {}
            @first_comment.author = @author
            @second_comment.author = @author

            serializable = SerializableResource.new(
              @first_comment,
              serializer: NestedCommentBelongsToSerializer,
              adapter: :json)

            expected = {
              comment: {
                id: 1, body: 'ZOMG A COMMENT',
                author: {
                  id: 1,
                  name: 'Steve K.',
                  posts: [
                    {
                      id: 42, title: 'New Post', body: 'Body'
                    }
                  ]
                }
              }
            }

            actual = serializable.serializable_hash

            assert_equal(expected, actual)
          end
        end
      end
    end
  end
end
