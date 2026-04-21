class VerseEmbedding < ApplicationRecord
  belongs_to :verse

  validates :embedding_data, presence: true
  validates :model_version, presence: true
  validates :verse_id, uniqueness: true

  # In-process cache of parsed embedding vectors, keyed nowhere — scanned
  # sequentially on every query. Rebuilt lazily on first access and
  # invalidated on any write via the callback below. This is the biggest
  # knob turning semantic search from ~1-3s per query (parse every
  # embedding's JSON every time) into ~30-80ms (scan cached float arrays).
  #
  # Caveat: each Puma worker has its own cache. A write in one worker
  # won't invalidate the others; acceptable because the corpus is static
  # after the one-shot embeddings:generate rake task and writes are
  # essentially never hit in production.
  after_commit :reset_embedding_cache

  scope :by_model, ->(version) { where(model_version: version) }

  def embedding
    @embedding ||= JSON.parse(embedding_data)
  end

  def embedding=(vector)
    self.embedding_data = vector.to_json
    @embedding = nil
  end

  def similarity_to(query_vector)
    self.class.cosine_similarity(embedding, query_vector)
  end

  def self.cosine_similarity(a, b)
    dot = 0.0
    mag_a = 0.0
    mag_b = 0.0
    i = 0
    len = a.length
    while i < len
      av = a[i]
      bv = b[i]
      dot   += av * bv
      mag_a += av * av
      mag_b += bv * bv
      i += 1
    end
    return 0.0 if mag_a.zero? || mag_b.zero?
    dot / (Math.sqrt(mag_a) * Math.sqrt(mag_b))
  end

  # Scores cached embeddings against the query vector and returns the top
  # `limit` Verse rows (with a `similarity_score` singleton) whose score
  # exceeds `threshold`. One DB round trip total: the Verse lookup at the
  # end. Cached vectors are the hot path; cold path rebuilds the cache
  # once (~200ms for a full KJV corpus).
  def self.search_by_similarity(query_embedding, limit: 20, threshold: 0.3, translation_codes: [ "KJV" ])
    codes = Array(translation_codes).map(&:to_s).map(&:upcase).to_set

    scored = cached_entries
               .select { |_, _, code| codes.include?(code) }
               .filter_map do |verse_id, vec, _code|
                 score = cosine_similarity(vec, query_embedding)
                 next if score < threshold
                 [ verse_id, score ]
               end
               .sort_by { |_, score| -score }
               .first(limit)

    return [] if scored.empty?

    verse_ids     = scored.map(&:first)
    scores_by_id  = scored.to_h
    verses_by_id  = Verse.where(id: verse_ids)
                         .includes(chapter: { book: :translation })
                         .index_by(&:id)

    verse_ids.map do |id|
      verse = verses_by_id[id]
      score = scores_by_id[id]
      verse.define_singleton_method(:similarity_score) { score }
      verse
    end
  end

  # Cached representation: array of [verse_id, embedding_array,
  # translation_code]. Loaded once per process; invalidated on any write.
  def self.cached_entries
    @cached_entries ||= build_cached_entries
  end

  def self.reset_cache!
    @cached_entries = nil
  end

  def self.build_cached_entries
    rows = joins(verse: { chapter: { book: :translation } })
             .pluck(:verse_id, :embedding_data, "translations.code")
    rows.map { |verse_id, json, code| [ verse_id, JSON.parse(json), code ] }
  end
  private_class_method :build_cached_entries

  private

  def reset_embedding_cache
    self.class.reset_cache!
  end
end
