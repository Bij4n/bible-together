require "rails_helper"

RSpec.describe Bible::RedLetterPatch do
  let!(:rv1909) { create(:translation, code: "RV1909", name: "Reina-Valera 1909", language: "es") }
  let(:john) do
    create(:book, osis_code: "John", translation: rv1909,
                  name_en: "John", name_es: "Juan", position: 43, testament: :new)
  end
  let(:chapter) { create(:chapter, book: john, number: 8) }
  let(:body) { "Y ella dijo: Señor, ninguno. Entonces Jesús le dijo: Ni yo te condeno: vete, y no peques más." }
  let!(:verse) do
    create(:verse, chapter: chapter, number: 11, body_text: body, body_html: body,
                   osis_ref: "Bible.RV1909.John.8.11")
  end

  def patch_file(entries)
    file = Tempfile.new([ "red_letter", ".yml" ])
    file.write(entries.to_yaml)
    file.close
    file.path
  end

  def apply(entries)
    described_class.call(translation_code: "RV1909", path: patch_file(entries))
  end

  it "turns the listed text red" do
    result = apply("John.8.11" => [ "Ni yo te condeno: vete, y no peques más." ])

    start = body.index("Ni yo")
    expect(verse.reload.red_letter_ranges).to eq([ [ start, body.length ] ])
    expect(result.updated).to eq(1)
  end

  it "supports a verse that turns red more than once" do
    apply("John.8.11" => [ "Ni yo te condeno:", "y no peques más." ])

    expect(verse.reload.red_letter_ranges.map { |s, e| body[s...e] })
      .to eq([ "Ni yo te condeno:", "y no peques más." ])
  end

  it "is safe to run twice" do
    entries = { "John.8.11" => [ "Ni yo te condeno: vete, y no peques más." ] }
    apply(entries)

    expect { apply(entries) }.not_to change { verse.reload.red_letter_ranges }
  end

  it "refuses to write anything when a passage is not in its verse" do
    other = create(:verse, chapter: chapter, number: 12, body_text: "Yo soy la luz del mundo.",
                           body_html: "Yo soy la luz del mundo.", osis_ref: "Bible.RV1909.John.8.12")

    expect {
      apply("John.8.12" => [ "Yo soy la luz del mundo." ], "John.8.11" => [ "Tampoco yo te condeno." ])
    }.to raise_error(described_class::Mismatch, /John\.8\.11/)

    expect(other.reload.red_letter_ranges).to eq([])
  end

  it "refuses to write when a verse is missing" do
    expect { apply("John.99.1" => [ "Yo soy." ]) }
      .to raise_error(described_class::Mismatch, /John\.99\.1/)
  end

  it "reports whether a translation has a patch file" do
    expect(described_class.exists_for?("RV1909_MINI")).to be true
    expect(described_class.exists_for?("NOPE")).to be false
  end
end
