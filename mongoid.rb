require 'mongoid'
require 'securerandom'
require 'binding_of_caller'

class DocumentID

  def initialize(id=nil)
    @id = self.class.gen_new_id
  end

  def mongoize
    @id
  end

  class << self

    def gen_new_id
      return SecureRandom.uuid
    end

    def demongoize(id)
      DocumentID.new(id)
    end

  end

  attr_reader :id

end

class ForignDocument

  def initialize(document)
    @document = document
    @docId = document.id.to_s
    @docType = document.class
  end

  def mongoize
    JSON.generate([@docId, @docType])
  end

  class << self

    def demongoize(identifier)
      puts "Restoring Forign Document: #{identifier}"
      docId, docType = JSON.parse(identifier)
      Object.const_get(docType).where("_id": docId).first
    end

  end

end

class DB

  extend Mongoid

  def initialize
    self.class.load!('./mongoid.yml', :development)
  end

end

class BaseTable


end

class Contact

  include Mongoid::Document

  store_in collection: "contacts", database: "test"

  field :document_id, type: DocumentID, default: ->{ DocumentID.new }

  field :created, type: DateTime, default: ->{ Time.now }
  field :updated, type: DateTime, default: ->{ Time.now }

  field :active, type: Boolean, default: true

  field :titel, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :telephone, type: String
  field :email, type: String
  field :language, type: String

  field :email_invoice, type: Boolean
  field :address, type: ForignDocument
  field :shipping_addres, type: ForignDocument

  set_callback(:save, :after) do |document|
    puts "Updating Document #{document} at #{Time.new}"
    Contact.skip_callback(:save, :after, :update_document)
    document.update(updated: Time.now) unless binding.of_caller(10).eval('__method__') == :update_document
    Contact.set_callback(:save, :after, :update_document)
    puts "Updated Document!" unless binding.of_caller(10).eval('__method__') == :update_document
  end


end

class Address

  include Mongoid::Document

  store_in collection: "addresses", database: "test"

  field :document_id, type: DocumentID, default: ->{ DocumentID.new }

  field :street, type: String
  field :city, type: String
  field :postalcode, type: String
  field :country, type: String

end


#Mongoid.load!('./mongoid.yml', :development)
db = DB.new
@flags = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10']
#100.times do |i|
#	Contact.create!(titel: 'Mr.', first_name: "#{i} First_name", last_name: "#{i} Last_name", email: "#{i}.user@db", age: Random.rand(17..67), flag: @flags.sample)
#end
#a1 = Address.create!(street: 'Allee1', city: 'Paderborn', postalcode: '33098', country: 'DE')
#c1 = Contact.create!(titel: 'Mr.', first_name: 'Stephan', last_name: 'Raab', email: 's.raab@raab.de')
#c1.invoice_address.create
#a1 = Address.where("_id": "58877f936e955209a85eecba").first
#puts a1.street
#a1.country = "EN"
#a1.save!
#c1 = Contact.where("id": "5889e5656e955209664bda22").first
#s2 = Contact.where("first_name": "Oliver").first
#puts c1.first_name == "119 First_name"
c1 = Contact.where("first_name": "Stephan").first
c1.update(email: "a@b.c")
#c1.first_name = "Test Contact"
sleep 1
c1.save
#c1.last_name = "voll der Otto"
#c1.save
#c1.address = ForignDocument.new(a1)
#c2.address = ForignDocument.new(a1)
#c2.save!
