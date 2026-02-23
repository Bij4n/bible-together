require "rails_helper"
require "rake"

RSpec.describe "config/bible_sources.yml for RV1909" do
  before(:all) do
    Rails.application.load_tasks unless defined?(BibleImportTask)
  end

  let(:entry) { BibleImportTask.load_entry("rv1909") }

  it "registers the RV1909 translation entry" do
    expect(entry).to be_a(Hash)
    expect(entry.fetch("name")).to eq("Reina-Valera 1909")
    expect(entry.fetch("language")).to eq("es")
    expect(entry.fetch("public_domain")).to be true
  end

  it "pins an HTTPS source URL and SHA256" do
    source = entry.fetch("source")
    expect(source.fetch("url")).to start_with("https://")
    expect(source.fetch("sha256")).to match(/\A[a-f0-9]{64}\z/)
    expect(source.fetch("filename")).to eq("spa-rv1909.osis.xml")
    expect(source.fetch("archive")).to be false
  end

  describe ".ensure_translation" do
    it "creates a Translation row with the config metadata" do
      expect {
        BibleImportTask.ensure_translation("rv1909", entry)
      }.to change(Translation, :count).by(1)

      t = Translation.find_by(code: "RV1909")
      expect(t.name).to eq("Reina-Valera 1909")
      expect(t.language).to eq("es")
      expect(t.public_domain).to be true
    end

    it "is idempotent on re-run" do
      BibleImportTask.ensure_translation("rv1909", entry)
      expect { BibleImportTask.ensure_translation("rv1909", entry) }
        .not_to change(Translation, :count)
    end
  end
end
