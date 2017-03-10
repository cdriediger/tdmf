#require_relative 'jimson/lib/jimson'
require 'jimson'
require 'securerandom'

class RPCClient

  def initialize(url)
    @url = url
    @namespaces = {}
  end

  def open_namespace(namespace, url=nil)
    url ||= @url
    opts = {}
    @namespaces[namespace] = Jimson::Client.new(url, opts, "#{namespace.to_s.capitalize}.")
  end

  def method_missing(namespace, *args, &block)
    @namespaces[namespace]
  end
end

client = RPCClient.new("http://127.0.0.1:8999")
client.open_namespace(:contacts)
client.open_namespace(:address)
a1 = client.address.create(street: 'Stephnausstr. 23', plz: '33098', city: 'Paderborn', country: 'Germany')
client.contacts.create(titel: 'Mr.', first_name: 'Christoph', last_name: 'Driediger', address: a1)
#puts client.contacts.get({"first_name":"Name4", last_name: 'Lastname4'}, ['created', 'updated'])
#puts '#############'
#puts client.contacts.get({"first_name":"Name4", last_name: 'Lastname4'})
#puts '###############'
#client.contacts.update({"first_name":"Name4", last_name: 'Lastname41'}, {last_name: 'Lastname4'})
#puts client.contacts.get({"first_name":"Name4", last_name: 'Lastname4'})



#client.open_namespace(:contacts, "http://christoph:123456@127.0.0.1:8080")
#puts client.article.new({:article_number => "1",:description => "test article descr",:name => "test1"})
#puts client.contacts.where("first_name": "Stephan")
#x = client.contacts.where("first_name": "Stephan").first
#puts x
#puts x.class
#x.titel = "Herr"
#x.save
