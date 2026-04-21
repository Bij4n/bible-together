require "rails_helper"

RSpec.describe EmbeddingService do
  let(:base_url) { EmbeddingService::BASE_URL }

  describe ".resolve_base_url" do
    it "uses EMBEDDING_SERVICE_URL when it is set" do
      stub_const("ENV", ENV.to_h.merge(
        "EMBEDDING_SERVICE_URL"  => "https://explicit.example.com",
        "EMBEDDING_SERVICE_HOST" => "ignored-host"
      ))
      expect(EmbeddingService.resolve_base_url).to eq("https://explicit.example.com")
    end

    it "builds the URL from EMBEDDING_SERVICE_HOST and default port 8000 when no explicit URL" do
      env = ENV.to_h.except("EMBEDDING_SERVICE_URL", "EMBEDDING_SERVICE_PORT").merge("EMBEDDING_SERVICE_HOST" => "embedding.internal")
      stub_const("ENV", env)
      expect(EmbeddingService.resolve_base_url).to eq("http://embedding.internal:8000")
    end

    it "honors EMBEDDING_SERVICE_PORT when building from host" do
      env = ENV.to_h.except("EMBEDDING_SERVICE_URL").merge(
        "EMBEDDING_SERVICE_HOST" => "embedding.internal",
        "EMBEDDING_SERVICE_PORT" => "9000"
      )
      stub_const("ENV", env)
      expect(EmbeddingService.resolve_base_url).to eq("http://embedding.internal:9000")
    end

    it "falls back to localhost when neither URL nor HOST is set" do
      env = ENV.to_h.except("EMBEDDING_SERVICE_URL", "EMBEDDING_SERVICE_HOST", "EMBEDDING_SERVICE_PORT")
      stub_const("ENV", env)
      expect(EmbeddingService.resolve_base_url).to eq("http://127.0.0.1:8000")
    end
  end

  describe ".embed_texts" do
    it "posts the texts and returns the parsed body" do
      stub_request(:post, "#{base_url}/embed")
        .with(
          body: { texts: [ "hello" ] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
        .to_return(
          status: 200,
          body: { embeddings: [ [ 0.1, 0.2, 0.3 ] ], model_version: "all-MiniLM-L6-v2" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = EmbeddingService.embed_texts([ "hello" ])
      expect(result["embeddings"]).to eq([ [ 0.1, 0.2, 0.3 ] ])
      expect(result["model_version"]).to eq("all-MiniLM-L6-v2")
    end

    it "wraps a single string in an array before sending" do
      stub_request(:post, "#{base_url}/embed")
        .with(body: { texts: [ "solo" ] }.to_json)
        .to_return(status: 200, body: { embeddings: [ [ 0.0 ] ], model_version: "m" }.to_json)

      expect { EmbeddingService.embed_texts("solo") }.not_to raise_error
    end

    it "raises EmbeddingError on a non-2xx response" do
      stub_request(:post, "#{base_url}/embed")
        .to_return(status: 500, body: "server exploded")

      expect { EmbeddingService.embed_texts([ "x" ]) }
        .to raise_error(EmbeddingService::EmbeddingError, /HTTP 500/)
    end

    it "raises EmbeddingError when the service is unreachable" do
      stub_request(:post, "#{base_url}/embed").to_raise(Errno::ECONNREFUSED)

      expect { EmbeddingService.embed_texts([ "x" ]) }
        .to raise_error(EmbeddingService::EmbeddingError, /Failed to reach/)
    end

    it "raises EmbeddingError on invalid JSON" do
      stub_request(:post, "#{base_url}/embed")
        .to_return(status: 200, body: "not json")

      expect { EmbeddingService.embed_texts([ "x" ]) }
        .to raise_error(EmbeddingService::EmbeddingError)
    end
  end

  describe ".healthy?" do
    it "returns true when the service reports healthy" do
      stub_request(:get, "#{base_url}/health")
        .to_return(status: 200, body: { status: "healthy", model: "all-MiniLM-L6-v2" }.to_json)

      expect(EmbeddingService.healthy?).to be true
    end

    it "returns false on non-2xx" do
      stub_request(:get, "#{base_url}/health").to_return(status: 503)
      expect(EmbeddingService.healthy?).to be false
    end

    it "returns false when the service is unreachable" do
      stub_request(:get, "#{base_url}/health").to_raise(Errno::ECONNREFUSED)
      expect(EmbeddingService.healthy?).to be false
    end

    it "returns false when the body lacks a healthy status" do
      stub_request(:get, "#{base_url}/health")
        .to_return(status: 200, body: { status: "degraded" }.to_json)
      expect(EmbeddingService.healthy?).to be false
    end
  end
end
