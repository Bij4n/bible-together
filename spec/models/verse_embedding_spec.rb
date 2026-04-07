require "rails_helper"

RSpec.describe VerseEmbedding, type: :model do
  describe "validations" do
    subject { build(:verse_embedding) }

    it { is_expected.to validate_presence_of(:embedding_data) }
    it { is_expected.to validate_presence_of(:model_version) }

    it "enforces one embedding per verse" do
      existing = create(:verse_embedding)
      dup      = build(:verse_embedding, verse: existing.verse)
      expect(dup).not_to be_valid
      expect(dup.errors[:verse_id]).to be_present
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:verse) }
  end

  describe "serialization" do
    it "round-trips a vector through #embedding / #embedding_data" do
      vec = Array.new(384) { |i| i / 1000.0 }
      ve  = build(:verse_embedding, embedding: vec)
      expect(ve.embedding_data).to be_a(String)
      expect(ve.embedding).to eq(vec)
    end

    it "reloads from the database as an array of floats" do
      vec = Array.new(384) { |i| i / 1000.0 }
      ve  = create(:verse_embedding, embedding: vec)
      expect(ve.reload.embedding).to eq(vec)
    end
  end

  describe "#similarity_to" do
    it "returns 1.0 for identical unit vectors" do
      vec = [ 1.0, 0.0 ] + Array.new(382, 0.0)
      ve  = build(:verse_embedding, embedding: vec)
      expect(ve.similarity_to(vec)).to be_within(0.0001).of(1.0)
    end

    it "returns 0.0 for orthogonal vectors" do
      a = [ 1.0, 0.0 ] + Array.new(382, 0.0)
      b = [ 0.0, 1.0 ] + Array.new(382, 0.0)
      ve = build(:verse_embedding, embedding: a)
      expect(ve.similarity_to(b)).to be_within(0.0001).of(0.0)
    end

    it "returns 0.0 when either vector is zero-magnitude" do
      zero = Array.new(384, 0.0)
      ve   = build(:verse_embedding, embedding: zero)
      expect(ve.similarity_to([ 1.0 ] + Array.new(383, 0.0))).to eq(0.0)
    end
  end

  describe ".by_model" do
    it "scopes to rows matching the given model_version" do
      a = create(:verse_embedding, model_version: "all-MiniLM-L6-v2")
      b = create(:verse_embedding, model_version: "mpnet-base-v2")
      expect(VerseEmbedding.by_model("all-MiniLM-L6-v2")).to contain_exactly(a)
      expect(VerseEmbedding.by_model("mpnet-base-v2")).to contain_exactly(b)
    end
  end

  describe ".search_by_similarity" do
    let!(:translation) { create(:translation, :kjv) }
    let!(:book)        { create(:book, :john, translation: translation) }
    let!(:chapter)     { create(:chapter, book: book, number: 3) }

    def verse_with_embedding(number:, vector:)
      verse = create(:verse, chapter: chapter, number: number,
                             body_text: "sample #{number}",
                             body_html: "sample #{number}",
                             osis_ref: "Bible.KJV.John.3.#{number}")
      create(:verse_embedding, verse: verse, embedding: vector)
      verse
    end

    it "orders verses by descending cosine similarity to the query" do
      near = verse_with_embedding(number: 1, vector: [ 1.0, 0.0 ] + Array.new(382, 0.0))
      mid  = verse_with_embedding(number: 2, vector: [ 0.9, 0.1 ] + Array.new(382, 0.0))
      far  = verse_with_embedding(number: 3, vector: [ 0.0, 1.0 ] + Array.new(382, 0.0))

      query   = [ 1.0, 0.0 ] + Array.new(382, 0.0)
      results = VerseEmbedding.search_by_similarity(query, limit: 3, threshold: 0.0)

      expect(results).to eq([ near, mid, far ])
    end

    it "filters out verses below the similarity threshold" do
      close = verse_with_embedding(number: 1, vector: [ 1.0, 0.0 ] + Array.new(382, 0.0))
      _far  = verse_with_embedding(number: 2, vector: [ 0.0, 1.0 ] + Array.new(382, 0.0))

      query   = [ 1.0, 0.0 ] + Array.new(382, 0.0)
      results = VerseEmbedding.search_by_similarity(query, limit: 5, threshold: 0.5)

      expect(results).to eq([ close ])
    end

    it "respects the limit argument" do
      3.times do |i|
        verse_with_embedding(number: i + 1,
                             vector: [ 1.0 - (i * 0.01), 0.0 ] + Array.new(382, 0.0))
      end
      query   = [ 1.0, 0.0 ] + Array.new(382, 0.0)
      results = VerseEmbedding.search_by_similarity(query, limit: 2, threshold: 0.0)
      expect(results.size).to eq(2)
    end

    it "attaches a similarity_score singleton to each returned verse" do
      verse_with_embedding(number: 1, vector: [ 1.0, 0.0 ] + Array.new(382, 0.0))
      query   = [ 1.0, 0.0 ] + Array.new(382, 0.0)
      result  = VerseEmbedding.search_by_similarity(query, limit: 1, threshold: 0.0).first
      expect(result.similarity_score).to be_within(0.0001).of(1.0)
    end
  end
end
