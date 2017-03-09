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
#client.contacts.create(titel: 'Mr.', first_name: 'Name2', last_name: 'Lastname2')
puts client.contacts.get({"first_name":"Name2"}, ['last_name'])



#client.open_namespace(:contacts, "http://christoph:123456@127.0.0.1:8080")
#puts client.article.new({:article_number => "1",:description => "test article descr",:name => "test1"})
#puts client.contacts.where("first_name": "Stephan")
#x = client.contacts.where("first_name": "Stephan").first
#puts x
#puts x.class
#x.titel = "Herr"
#x.save
