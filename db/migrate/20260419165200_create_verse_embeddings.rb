class CreateVerseEmbeddings < ActiveRecord::Migration[8.1]
  # Sprint 9 chose a pgvector-free implementation to avoid a system
  # dependency that required host-level sudo. Embeddings are stored
  # as JSON text and cosine similarity is computed in Ruby over the
  # ~31k-row KJV corpus. Swapping to pgvector later is a migration
  # to change `embedding_data text` → `embedding vector(384)` plus a
  # rewrite of VerseEmbedding.search_by_similarity; nothing upstream
  # of the model needs to change.
  def change
    create_table :verse_embeddings do |t|
      t.references :verse, null: false, foreign_key: true, index: { unique: true }
      t.text :embedding_data, null: false
      t.string :model_version, null: false, default: "all-MiniLM-L6-v2"
      t.timestamps
    end
  end
end
