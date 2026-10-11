require "rails_helper"

RSpec.describe Bible::RedLetterProposer do
  def propose(source, source_ranges, target)
    described_class.call(source_text: source, source_ranges: source_ranges, target_text: target)
  end

  def red(result, target)
    result.ranges.map { |s, e| target[s...e] }
  end

  it "starts after the colon when the source turns red mid-verse and stays red" do
    en = "And Jesus said unto him, This day is salvation come to this house."
    es = "Y Jesús le dijo: Hoy ha venido la salvación á esta casa."

    result = propose(en, [ [ 25, en.length ] ], es)

    expect(red(result, es)).to eq([ "Hoy ha venido la salvación á esta casa." ])
    expect(result).to be_confident
  end

  it "picks the colon closest to where the source turns red, and flags the guess" do
    en = "She said, No man, Lord. And Jesus said unto her, Neither do I condemn thee: go, and sin no more."
    es = "Y ella dijo: Señor, ninguno. Entonces Jesús le dijo: Ni yo te condeno: vete, y no peques más."

    result = propose(en, [ [ 49, en.length ] ], es)

    expect(red(result, es)).to eq([ "Ni yo te condeno: vete, y no peques más." ])
    expect(result).not_to be_confident
  end

  it "ends at the nearest sentence break when narration follows the speech" do
    en = "And Jesus put forth his hand, and touched him, saying, I will; be thou clean. " \
         "And immediately his leprosy was cleansed."
    es = "Y extendiendo Jesús su mano, le tocó, diciendo: Quiero; sé limpio. Y luego su lepra fué limpiada."

    result = propose(en, [ [ 55, 77 ] ], es)

    expect(red(result, es)).to eq([ "Quiero; sé limpio." ])
    expect(result).not_to be_confident
  end

  it "keeps the start of the verse red when the source opens red" do
    en = "And they shall kill him, and the third day he shall be raised again. And they were exceeding sorry."
    es = "Y le matarán; mas al tercer día resucitará. Y ellos se entristecieron en gran manera."

    result = propose(en, [ [ 0, 68 ] ], es)

    expect(red(result, es)).to eq([ "Y le matarán; mas al tercer día resucitará." ])
  end

  it "treats a source range that stops one character short as the whole verse" do
    en = "All things are delivered unto me of my Father."
    es = "Todas las cosas me son entregadas de mi Padre."

    result = propose(en, [ [ 0, en.length - 1 ] ], es)

    expect(result.ranges).to eq([ [ 0, es.length ] ])
    expect(result).to be_confident
  end

  it "maps each range of a verse that turns red twice" do
    en = "Whether of them twain did the will of his father? They say unto him, The first. " \
         "Jesus saith unto them, Verily I say unto you."
    es = "¿Cuál de los dos hizo la voluntad de su padre? Dicen ellos: El primero. " \
         "Díceles Jesús: De cierto os digo."

    result = propose(en, [ [ 0, 50 ], [ 103, en.length ] ], es)

    expect(red(result, es)).to eq([ "¿Cuál de los dos hizo la voluntad de su padre?", "De cierto os digo." ])
    expect(result).not_to be_confident
  end

  it "proposes nothing when the target has no colon to anchor on" do
    en = "And he said unto them, That the Son of man is Lord also of the sabbath."
    es = "Y les decía. El Hijo del hombre es Señor aun del sábado."

    result = propose(en, [ [ 23, en.length ] ], es)

    expect(result.ranges).to be_nil
    expect(result).not_to be_confident
  end
end
