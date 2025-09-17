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
    @content.paths.map do |path, path_content|
      schema = path_content.get.responses['200'].content["application/json"].schema
      properties = extract_properties(schema)
      { path: path, properties: properties }
    end
  end

  private

  def extract_properties(schema)
    recursive_extract_properties(schema, [])
  end

  def recursive_extract_properties(schema, properties)
    if schema.keys.include?("properties")
      recursive_extract_properties(schema.properties, properties)
    else
      properties += schema.values.map(&:to_h)
    end
  end

  def get_content
    Openapi3Parser.load_url(@swagger_url)
  end
end


swagger = Swagger.new(SWAGGER_URLS[:api_particulier])
p swagger.extract_fields