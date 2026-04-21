require "net/http"
require "json"
require "uri"

# Thin client for the Python embedding service. Two endpoints:
#
#   embed_texts(["text", ...])  -> { "embeddings" => [[...], ...], "model_version" => "..." }
#   healthy?                     -> Boolean
#
# Any network / parse failure bubbles up as EmbeddingError so callers
# (SemanticSearchService, the batch rake task) can fall through
# cleanly.
class EmbeddingService
  HEALTH_TIMEOUT = 5
  EMBED_TIMEOUT  = 30

  class EmbeddingError < StandardError; end

  # Resolves the embedding service URL at boot. Prefers an explicit
  # EMBEDDING_SERVICE_URL, otherwise builds from EMBEDDING_SERVICE_HOST
  # (+ optional port). Host-based resolution is how Render's
  # `fromService: property: host` wiring reaches us — the private
  # service's hostname is injected as HOST, not as a full URL.
  def self.resolve_base_url
    explicit = ENV["EMBEDDING_SERVICE_URL"]
    return explicit if explicit.present?

    host = ENV["EMBEDDING_SERVICE_HOST"]
    return "http://127.0.0.1:8000" unless host.present?

    port = ENV.fetch("EMBEDDING_SERVICE_PORT", "8000")
    "http://#{host}:#{port}"
  end

  BASE_URL = resolve_base_url.freeze

  def self.embed_texts(texts)
    uri = URI("#{BASE_URL}/embed")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = { texts: Array(texts) }.to_json

    response = http(uri, timeout: EMBED_TIMEOUT).request(request)
    unless response.is_a?(Net::HTTPSuccess)
      raise EmbeddingError, "HTTP #{response.code}: #{response.body}"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError, SocketError, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
    raise EmbeddingError, "Failed to reach embedding service: #{e.message}"
  end

  def self.healthy?
    uri = URI("#{BASE_URL}/health")
    response = http(uri, timeout: HEALTH_TIMEOUT).get(uri.request_uri)
    return false unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)["status"] == "healthy"
  rescue StandardError
    false
  end

  def self.http(uri, timeout:)
    Net::HTTP.new(uri.host, uri.port).tap do |http|
      http.open_timeout = timeout
      http.read_timeout = timeout
      http.use_ssl = (uri.scheme == "https")
    end
  end
  private_class_method :http
end
