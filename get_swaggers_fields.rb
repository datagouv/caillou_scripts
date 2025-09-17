require "openapi3_parser"

SWAGGER_URLS = {
  api_particulier: "https://particulier.api.gouv.fr/open-api-without-deprecated-paths.yml",
  api_entreprise: "https://entreprise.api.gouv.fr/open-api-without-deprecated-paths.yml",
}

class Swagger
  def initialize(swagger_url)
    @swagger_url = swagger_url
    @content = get_content
  end

  def paths
    @content.paths.keys
  end

  def extract_fields
    fields_per_paths = @content.paths.map do |path, path_content|
      schema = path_content.get.responses['200'].content["application/json"].schema
      properties = extract_properties(schema)
      properties.map{|p| [path, p].join("\t")}
    end
    fields_per_paths
  end

  private

  def extract_properties(schema)
    recursive_extract_properties(schema, [])
  end

  def recursive_extract_properties(schema, properties)
    return properties unless schema
    
    # Handle schema with properties (object type)
    if schema.respond_to?(:properties) && schema.properties
      schema.properties.each do |prop_name, prop_schema|
        # Only add properties that are leaf-level (no nested properties)
        if interesting_properties(prop_schema) && !has_nested_properties(prop_schema)
          properties << prop_schema.to_h
        end
        
        # Recursively extract nested properties
        recursive_extract_properties(prop_schema, properties)
      end
    # Handle array schemas
    elsif schema.respond_to?(:items) && schema.items
      recursive_extract_properties(schema.items, properties)
    # Handle schema composition (allOf, oneOf, anyOf)
    elsif schema.respond_to?(:all_of) && schema.all_of
      schema.all_of.each { |sub_schema| recursive_extract_properties(sub_schema, properties) }
    elsif schema.respond_to?(:one_of) && schema.one_of
      schema.one_of.each { |sub_schema| recursive_extract_properties(sub_schema, properties) }
    elsif schema.respond_to?(:any_of) && schema.any_of
      schema.any_of.each { |sub_schema| recursive_extract_properties(sub_schema, properties) }
    end
    
    properties
  end

  def interesting_properties(prop_schema)
    prop_schema.respond_to?(:type) && prop_schema.type && 
    prop_schema.respond_to?(:title) && prop_schema.title
  end

  def has_nested_properties(prop_schema)
    # Check if the property has nested properties (is a container object)
    prop_schema.respond_to?(:properties) && prop_schema.properties && 
    prop_schema.properties.any?
  end

  def get_content
    Openapi3Parser.load_url(@swagger_url)
  end
end


# Example usage
swagger = Swagger.new(SWAGGER_URLS[:api_particulier])
print swagger.extract_fields.join("\n")