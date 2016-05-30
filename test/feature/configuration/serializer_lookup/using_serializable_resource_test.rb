require 'test_helper'

describe 'feature' do
  describe 'configuration' do
    describe 'serializer lookup' do
      describe 'using SerializableResource' do
        it 'uses the child serializer' do
          class Parent < ::Model; end
          class Child < ::Model; end

          class ParentSerializer < ActiveModel::Serializer
            class ChildSerializer < ActiveModel::Serializer
              attributes :name, :child_attr
              def child_attr
                true
              end
            end

            attributes :name
            belongs_to :child
          end

          parent = Parent.new(name: 'parent', child: Child.new(name: 'child'))
          resource = ActiveModelSerializers::SerializableResource.new(
            parent,
            adapter: :attributes
          )

          expected = {
            name: 'parent',
            child: {
              name: 'child',
              child_attr: true
            }
          }

          assert_equal expected, resource.serializable_hash
        end
      end
    end
  end
end
