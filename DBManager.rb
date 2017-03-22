class DBManager

  extend Mongoid

  def initialize
    self.class.load!('./mongoid.yml', :development)
    #config_client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'test')
    #config = client[:config]
    #@default_fields = config.find({configname: 'default_fields'})
  end

  def load_model(model_name, plugin_file_path)
    @model_name = model_name
    model_filepath = plugin_file_path.split('.')[0..-2].join('.') + '.model'
    puts model_filepath
    model_definition = JSON.parse(File.open(model_filepath).read)

    @model_controller = Class.new(Object.const_get(@model_name + 'Controller')) do
      @model = Class.new do
        include Mongoid::Document
        if model_definition.has_key?('store_in')
          store_in database: model_definition['store_in']['database'] if model_definition['store_in'].has_key?('database')
          store_in collection: model_definition['store_in']['collection'] if model_definition['store_in'].has_key?('collection')
        end

	@@name = model_name.clone

        field :document_id, type: DocumentID, default: ->{ DocumentID.new(model_name) }
        field :created, type: DateTime, default: ->{ Time.now }
        field :updated, type: DateTime, default: ->{ Time.now }
        field :active, type: Boolean, default: true

	@@fields = model_definition['fields']
        @@fields.each_pair do |field_name, file_attributes|
          field_type = file_attributes['type']

          field field_name.to_sym, type: Object.const_get(field_type)
          puts "Adding Field: #{field_name} Type: #{field_type}"
        end

	def self.forign_documents
	  return self.fields.select { |key, val| val.type.to_s == "ForignDocument" }.keys
	end

	def self.name
	  return @@name
	end

      end

      def self.create(data)
        puts "Creating new #{@model.name}"
        data.each_pair do |key, val|
	  puts "Testing if #{key} is a ForignDocument"
	  if @model.forign_documents.include?(key)
     	    data[key] = ForignDocument.new(val) if @model.forign_documents.include?(key)
	    puts "Found ForignDocument: #{key}"
	  end
	end
	puts "Finaly creating Document with Data: #{data}"
	doc = @model.create!(data)
	puts doc
	puts doc.class
	return doc[:document_id]
      end

      def self.get_by_id(id, selected_keys=nil)
        return self.get({document_id: id}, selected_keys)
      end

      def self.get(filter, selected_keys=nil)
	puts "called Get Filter: #{filter}, selected_keys: #{selected_keys}"
	result = []
	if selected_keys
	  @model.where(filter).each do |entry|
	    entry = entry.to_h.select do |key, value|
              puts "test if #{key} in #{selected_keys}"
              selected_keys.include?(key)
	    end
	    entry.delete("_id")
	    result << entry
	  end
	else
      	  @model.where(filter).each do |entry|
            puts "Got Entry from Database: #{entry}"
            entry.each do |field|
	      puts "Found field in Entry: #{field}"
	    end
	    entry.delete("_id")
	    result <<  entry
	  end
	end
	return result
      end

      def self.update(filter, modifier)
	modifier['updated'] = Time.now
        doc = @model.where(filter).update(modifier)
	return doc[0][:document_id]
      end

      def self.delete(filter)
	@model.where(filter).delete
      end
    end

    Object.const_set(@model_name, @model_controller)
    puts "Created Class #{@model_name}"
  end
end

class DocumentID

  def initialize(model_name)
    puts "Creating DocumentID for Model: #{model_name}"
    @id = model_name + "#" + self.class.gen_new_id
    @type = model_name
  end

  def mongoize
    @id
  end

  class << self

    def gen_new_id
      return SecureRandom.uuid
    end

    def demongoize(id)
      return nil unless id
      DocumentID.new(id)
    end

  end

  attr_reader :id

end

class ForignDocument

  def initialize(doc_id)
    @doc_id = doc_id
    puts "Creating ForingDocument ID: #{@doc_id}"
  end

  def mongoize
    @doc_id
  end

  class << self

    def demongoize(id)
      puts "Restoring Forign Document: #{id}"
      type = id.split('#')[0]
      puts "Type of Object: #{type}"
      Object.const_get(type).get({"document_id": id}).first
    end

  end

end
