require './print.rb'

# Base interface for knowledge graph clients
class KnowledgeGraphInterface
  def initialize(config)
    @config = config
    @initialized = false
  end

  # Abstract methods that must be implemented by subclasses
  def connect
    raise NotImplementedError, "Subclasses must implement connect"
  end

  def disconnect
    raise NotImplementedError, "Subclasses must implement disconnect"
  end

  def create_node(node_id, labels, properties)
    raise NotImplementedError, "Subclasses must implement create_node"
  end

  def create_relationship(from_node_id, to_node_id, relationship_type, properties)
    raise NotImplementedError, "Subclasses must implement create_relationship"
  end

  def find_nodes_by_label(label, limit = 10)
    raise NotImplementedError, "Subclasses must implement find_nodes_by_label"
  end

  def find_nodes_by_property(property_name, property_value, limit = 10)
    raise NotImplementedError, "Subclasses must implement find_nodes_by_property"
  end

  def find_relationships(node_id, relationship_type = nil, direction = nil)
    raise NotImplementedError, "Subclasses must implement find_relationships"
  end

  def search_nodes(search_query, limit = 10)
    raise NotImplementedError, "Subclasses must implement search_nodes"
  end

  def get_node_context(node_id, max_depth = 2, max_nodes = 20)
    raise NotImplementedError, "Subclasses must implement get_node_context"
  end

  def delete_node(node_id)
    raise NotImplementedError, "Subclasses must implement delete_node"
  end

  def test_connection
    raise NotImplementedError, "Subclasses must implement test_connection"
  end

  # Helper methods
  def connected?
    @initialized
  end

  def validate_node_id(node_id)
    raise ArgumentError, "Node ID cannot be nil" if node_id.nil?
    raise ArgumentError, "Node ID cannot be empty" if node_id.to_s.strip.empty?
  end

  def validate_labels(labels)
    raise ArgumentError, "Labels cannot be nil" if labels.nil?
    raise ArgumentError, "Labels must be an array" unless labels.is_a?(Array)
    raise ArgumentError, "Labels array cannot be empty" if labels.empty?

    labels.each do |label|
      raise ArgumentError, "Label cannot be empty" if label.to_s.strip.empty?
      raise ArgumentError, "Label contains invalid characters" unless label.to_s.match?(/^[a-zA-Z0-9_-]+$/)
    end
  end

  def validate_properties(properties)
    return nil if properties.nil?
    raise ArgumentError, "Properties must be a hash" unless properties.is_a?(Hash)

    properties.each do |key, value|
      raise ArgumentError, "Property key cannot be empty" if key.to_s.strip.empty?
      # Basic validation - ensure property values are serializable
      begin
        JSON.generate(value)
      rescue => e
        raise ArgumentError, "Property value '#{key}' is not serializable: #{e.message}"
      end
    end
  end

  def validate_relationship_type(relationship_type)
    raise ArgumentError, "Relationship type cannot be nil" if relationship_type.nil?
    raise ArgumentError, "Relationship type cannot be empty" if relationship_type.to_s.strip.empty?
    raise ArgumentError, "Relationship type contains invalid characters" unless relationship_type.to_s.match?(/^[A-Z_][A-Z0-9_]*$/)
  end

  # Helper method to normalize search queries
  def normalize_search_query(query)
    return nil if query.nil?
    normalized = query.to_s.downcase.strip.gsub(/[^\w\s]/, ' ')
    normalized.gsub(/\s+/, ' ').strip
  end

  # Helper method to create a unique ID from text
  def create_id_from_text(text, prefix = '')
    return nil if text.nil?
    normalized = normalize_search_query(text)
    "#{prefix}_#{normalized.gsub(/\s+/, '_')}"
  end

  # Helper method to extract entities from text (basic implementation)
  def extract_entities_from_text(text, entity_types = [])
    return [] if text.nil? || text.empty?

    entities = []

    # Basic entity extraction using regex patterns
    # This can be enhanced with more sophisticated NLP techniques
    patterns = {
      'ip_address' => /\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b/,
      'url' => /\b(?:https?:\/\/)?(?:www\.)?[\w\.-]+\.[a-z]{2,}(?:\/\S*)?\b/i,
      'email' => /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/,
      'port' => /\b(?:[0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])\b/,
      'hash' => /\b[a-f0-9]{32,64}\b/i,
      'filename' => /\b[\w\.-]+\.(?:exe|dll|so|sh|py|rb|js|bat|ps1|scr|com|pif)\b/i
    }

    # Filter by requested entity types if specified
    target_patterns = entity_types.empty? ? patterns : patterns.select { |k, v| entity_types.include?(k) }

    target_patterns.each do |entity_type, pattern|
      matches = text.scan(pattern)
      matches.uniq.each do |match|
        entities << {
          type: entity_type,
          value: match,
          position: text.index(match)
        }
      end
    end

    # Sort by position
    entities.sort_by { |e| e[:position] }
  end
end
