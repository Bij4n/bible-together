FactoryBot.define do
  factory :verse_embedding do
    association :verse
    # Deterministic 384-dim vector so specs don't need the real
    # sentence-transformers model. The `embedding=` setter on the
    # model serialises this to JSON into `embedding_data`.
    embedding { Array.new(384) { |i| ((i % 7) + 1) / 10.0 } }
    model_version { "all-MiniLM-L6-v2" }
  end
end
