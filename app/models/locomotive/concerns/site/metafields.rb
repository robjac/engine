module Locomotive
  module Concerns
    module Site
      module Metafields

        extend ActiveSupport::Concern

        included do

          ## fields ##
          field :metafields,        type: Hash, default: {}
          field :metafields_schema, type: Array, default: []

          ## validations ##
          validate :validate_metafields_schema

        end

        def has_metafields?
          !self.metafields_schema.blank?
        end

        def any_localized_metafield?
          return false unless self.has_metafields?

          self.metafields_schema.any? { |g| g['fields'].any? { |f| f['localized'] ==  true } }
        end

        def find_metafield(name)
          return nil if name.blank? || !has_metafields?

          fields = self.metafields_schema.map { |g| g['fields'] }.flatten

          fields.find do |f|
            _name = f['name'].downcase.underscore.gsub(' ', '_')
            _name == name
          end
        end

        def metafields_schema=(schema)
          super(schema.is_a?(String) ? ActiveSupport::JSON.decode(schema) : schema)
        end

        def metafields=(values)
          super(values.is_a?(String) ? ActiveSupport::JSON.decode(values) : values)
        end

        protected

        def validate_metafields_schema
          return if metafields_schema.blank?

          begin
            JSON::Validator.validate!(metafields_schema_schema, metafields_schema)
          rescue JSON::Schema::ValidationError
            self.errors.add(:metafields_schema, $!.message)
          end
        end

        def metafields_schema_schema
          {
            'id' => 'http://locomotive.works/schemas/metafields.json',
            'definitions' => {
              'field' => {
                'type' => 'object',
                'properties' => {
                  'name' => { 'type' => 'string', 'not': { 'enum': ['dom_id', 'model_name', 'method_missing', '_name', '_label', '_position', '_fields', '_t'] } },
                  'label' => { 'type' => ['string', 'object'] },
                  'hint' => { 'type' => ['string', 'object'] },
                  'type' => { 'enum': ['string', 'text', 'integer', 'float', 'file', 'image', 'boolean', 'select', 'color'] },
                  'position' => { 'type' => 'integer' },
                  'select_options' => { 'type' => ['object', 'array'] },
                  'localized' => { 'type' => 'boolean' },
                },
                'required' => ['name']
              }
            },
            'type' => 'array',
            'items' => {
              'type' => 'object',
              'properties' => {
                  'name'      => { 'type' => 'string' },
                  'label'     => { 'type' => ['string', 'object'] },
                  'fields'    => { 'type' => 'array', 'items': {'$ref': '#/definitions/field' } },
                  'position'  => { 'type' => 'integer', 'minimum' => 0 }
                },
              'required' => ['name', 'fields']
            }
          }
        end

      end

    end
  end
end
