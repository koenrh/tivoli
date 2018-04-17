# frozen_string_literal: true

require 'csv'
require 'prawn'
require 'i18n'
require 'dry-types'
require 'dry-struct'

Prawn::Font::AFM.hide_m17n_warning = true

I18n.load_path << 'locale/nl.yml'
I18n.locale = :nl

csv_file = ARGV[0]

# Types module contains some reusable types.
module Types
  include Dry::Types.module
  PostalCode = Types::Strict::String.constrained(
    format: /\A[0-9]{4}\ [A-Z]{2}\z/
  )
end

# Contacts reprensts an entry in the addressbook
class Contact < Dry::Struct
  attribute :name, Types::String
  attribute :address, Types::String
  attribute :postal_code, Types::PostalCode
  attribute :city, Types::String
end

# Addressbook contains contacts to send data access requests to.
class Addressbook
  def initialize(csv_string)
    @csv = CSV.parse(csv_string, headers: false)

    first_row = @csv[0]
    @me = Contact.new(name: first_row[0],
                      address: first_row[1],
                      postal_code: first_row[2],
                      city: first_row[3])
  end

  def each
    csv.each_with_index do |row, index|
      next if index.zero?
      yield Contact.new(
        name: row[0],
        address: row[1],
        postal_code: row[2],
        city: row[3]
      )
    end
  end

  attr_reader :me

  private

  attr_reader :csv
end

# Tivoli allows you to generate a data access request PDFs based on CSVs.
class Tivoli
  def initialize(csv_path:)
    @addressbook = Addressbook.new(File.read(csv_path))
  end

  def generate_requests
    FileUtils.mkdir_p('out') unless File.directory?('out')

    addressbook.each do |contact|
      builder = DocumentBuilder.new(sender: addressbook.me, recipient: contact)
      builder.build
    end
  end

  private

  attr_reader :requester, :addressbook
end

# DocumentBuilder creates a PDF document.
class DocumentBuilder
  def initialize(sender:, recipient:)
    @sender = sender
    @recipient = recipient
    @date = I18n.localize(Time.now, format: '%d %B %Y')
    @file_name = "out/#{recipient.name.tr(' ', '_').downcase}_"\
      "#{Time.now.strftime('%Y%m%d')}.pdf"
  end

  def build
    Prawn::Document.generate(file_name) do |pdf|
      pdf.text sender.name
      pdf.text sender.address
      pdf.text "#{sender.postal_code} #{sender.city}"

      pdf.move_down 40

      pdf.text recipient.name
      pdf.text recipient.address
      pdf.text "#{recipient.postal_code} #{recipient.city}"

      pdf.move_down 40

      pdf.text "#{sender.city}, #{date}"

      pdf.move_down 20

      pdf.text 'Betreft: inzageverzoek op grond van de Wet bescherming '\
        'persoonsgegevens (Wbp)'

      pdf.move_down 20

      pdf.text 'Geachte heer, mevrouw,'

      pdf.move_down 20

      pdf.text 'Hierbij verzoek ik u na te gaan of u persoonsgegevens van mij '\
        'verwerkt. Als u persoonsgegevens van mij verwerkt, wil ik hier graag '\
        'inzage in hebben. Ik verwacht een volledig en begrijpelijk overzicht '\
        'met daarin opgenomen de gegevens en de categorieën van gegevens '\
        'waartoe zij behoren, met welke doelen u mijn gegevens verwerkt en de '\
        'beschikbare informatie over de herkomst van mijn gegevens. Ook wil '\
        'ik weten wie de ontvangers zijn of wat de categorieën van ontvangers '\
        'zijn. Bovendien verzoek ik u hierbij expliciet om mij mede te delen '\
        'welke logica aan de verwerkingen ten grondslag ligt. Tot slot '\
        'verzoek ik u om het nummer van de melding van de verwerking bij de '\
        'Autoriteit Persoonsgegevens.'

      pdf.move_down 20

      pdf.text 'Dit verzoek heeft een wettelijke grondslag in artikel 35 van '\
        'de Wet bescherming persoonsgegevens (Wbp). Wellicht ten overvloede '\
        'vermeld ik dat in lid 1 van het wetsartikel een termijn van vier '\
        'weken wordt genoemd waarin u aan dit verzoek moet voldoen.'

      pdf.move_down 20

      pdf.text 'Ik heb een kopie van mijn identiteitsbewijs als bijlage '\
        'opgenomen zodat u mijn identiteit kunt vaststellen.'

      pdf.move_down 20

      pdf.text 'Hoogachtend,'

      pdf.move_down 20

      pdf.text sender.name
    end
  end

  private

  attr_reader :sender, :recipient, :file_name, :date
end

tivoli = Tivoli.new(csv_path: csv_file)
tivoli.generate_requests

puts 'done'
