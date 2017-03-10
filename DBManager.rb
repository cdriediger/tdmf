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

        field :document_id, type: DocumentID, default: ->{ DocumentID.new }
        field :created, type: DateTime, default: ->{ Time.now }
        field :updated, type: DateTime, default: ->{ Time.now }
        field :active, type: Boolean, default: true

        @fields = model_definition['fields']
        @fields.each_pair do |field_name, file_attributes|
          field_type = file_attributes['type']

          field field_name.to_sym, type: Object.const_get(field_type)
          puts "Adding Field: #{field_name} Type: #{field_type}"
        end

	def self.forign_documents
	  return self.fields.select { |key, val| val.type.to_s == "ForignDocument" }.keys
	end

      end

      def self.create(*args)
        args[0].each_pair do |key, val|
	  args[0][key] = ForignDocument.new(val) if @model.forign_documents.include?(key)
	end
	doc = @model.create!(args)
	return doc[0][:document_id]
      end

      def self.get_by_id(id, selected_keys=nil)
        return self.get({document_id: id}, selected_keys)
      end

      def self.get(filter, selected_keys=nil)
	puts "called Get Filter: #{filter}, selected_keys: #{selected_keys}"
	result = []
	if selected_keys
	  @model.where(filter).each do |entry|
	    entry = entry.as_document.to_h.select do |key, value|
              puts "test if #{key} in #{selected_keys}"
              selected_keys.include?(key)
	    end
	    entry.delete("_id")
	    result << entry
	  end
	else
      	  @model.where(filter).each do |entry|
            entry = entry.as_document.to_h
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

  def initialize
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
      return nil unless id
      DocumentID.new(id)
    end

  end

  attr_reader :id

end

class ForignDocument

  def initialize(doc_id, doc_type)
    @doc_id = doc_id
    @doc_type = doc_type
    @document = 
    @docType = document.class
  end

  def mongoize
    JSON.generate([@docId, @docType])
  end

  class << self

    def demongoize(id)
      return nil unless id
      puts "Restoring Forign Document: #{id}"
      docId, docType = JSON.parse(id)
      Object.const_get(docType).where("_id": docId).first
    end

  end

end
