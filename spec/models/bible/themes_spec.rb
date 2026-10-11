require "rails_helper"

RSpec.describe Bible::Themes do
  let(:themes) { described_class.all }

  it "gives every theme a unique, url-safe slug and a name in both languages" do
    slugs = themes.map(&:slug)

    expect(slugs).to all(match(/\A[a-z0-9]+(-[a-z0-9]+)*\z/))
    expect(slugs.uniq).to eq(slugs)
    themes.each do |theme|
      expect(theme.name_en).to be_present, "#{theme.slug}: no English name"
      expect(theme.name_es).to be_present, "#{theme.slug}: no Spanish name"
    end
  end

  it "names a theme in the current locale" do
    theme = described_class.find("forgiveness")

    expect(theme.name).to eq(theme.name_en)
    I18n.with_locale(:es) { expect(theme.name).to eq(theme.name_es) }
  end

  it "finds the passages tagged with a theme" do
    slugs = described_class.find("forgiveness").passages.map(&:slug)

    expect(slugs).to include("prodigal-son", "woman-caught-in-adultery")
  end

  # The point of a theme page is to set what he said beside what he did.
  it "pairs something he said with something he did under every theme" do
    themes.each do |theme|
      kinds = theme.passages.map(&:kind)

      expect(kinds).to include("encounter"), "#{theme.slug}: no encounter"
      expect(kinds & %w[parable word_picture saying]).to be_present, "#{theme.slug}: nothing he said"
    end
  end
end
