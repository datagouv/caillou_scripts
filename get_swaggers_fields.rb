require "openapi3_parser"
require "csv"

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
      [path, properties]
    end.to_h
  end

  def extract_fields_csv
    fields_per_paths = extract_fields

    CSV.generate(col_sep: "\t") do |csv|
      csv << ["Path", "Title", "Parents", "Type", "Description", "Example"]
      fields_per_paths.each do |path, fields|
        fields.each do |field|
          csv << [path, field[:title], field[:parent], field[:type], field[:description], field[:example]]
        end
      end
    end
  end

  private

  def extract_properties(schema)
    properties = recursive_extract_properties(schema, [])
    properties.map{|p| format_property(p)}
  end

  def recursive_extract_properties(schema, properties, parent_info = nil)
    return properties unless schema
    
    # Handle schema with properties (object type)
    if schema.respond_to?(:properties) && schema.properties
      schema.properties.each do |prop_name, prop_schema|
        leaf_property = prop_schema.to_h
        leaf_property["parent"] = parent_info
        
        # Only add properties that are leaf-level (no nested properties)
        if interesting_properties(prop_schema) && !has_nested_properties(prop_schema)
          properties << leaf_property
        end
        
        # Recursively extract nested properties with updated parent info
        recursive_extract_properties(prop_schema, properties, leaf_property)
      end
    # Handle array schemas
    elsif schema.respond_to?(:items) && schema.items
      recursive_extract_properties(schema.items, properties, parent_info)
    # Handle schema composition (allOf, oneOf, anyOf)
    elsif schema.respond_to?(:all_of) && schema.all_of
      schema.all_of.each { |sub_schema| recursive_extract_properties(sub_schema, properties, parent_info) }
    elsif schema.respond_to?(:one_of) && schema.one_of
      schema.one_of.each { |sub_schema| recursive_extract_properties(sub_schema, properties, parent_info) }
    elsif schema.respond_to?(:any_of) && schema.any_of
      schema.any_of.each { |sub_schema| recursive_extract_properties(sub_schema, properties, parent_info) }
    end
    
    properties
  end

  def format_property(leaf_property)
    {
      title: leaf_property["title"],
      parent: leaf_property["parent"] ? full_nested_title(leaf_property["parent"]) : nil,
      type: leaf_property["type"],
      description: leaf_property["description"],
      example: leaf_property["example"],
    }
  end

  def full_nested_title(leaf_property)
    titles = []
    if leaf_property["parent"]
      parent_title = full_nested_title(leaf_property["parent"])
      titles << parent_title unless parent_title.empty?
    end
    titles << leaf_property["title"]
    titles.join(" > ")
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
print swagger.extract_fields_csv


