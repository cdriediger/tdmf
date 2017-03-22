require 'rubygems'
#require 'jimson'
#require 'mongoid'
require 'binding_of_caller'
require_relative 'DBManager2'
require_relative 'PluginManager'
require_relative 'jimson/lib/jimson'

class RPCServer < Jimson::Server

  def initialize(opts = {})
    @router = Jimson::Router.new
    @router.namespace 'system', System.new(@router)
    @host = opts.delete(:host) || '0.0.0.0'
    @port = opts.delete(:port) || 8999
    @show_errors = opts.delete(:show_errors) || false
    @opts = opts
  end

  def add_namespace(handler, namespace=nil)
    if namespace
      namespace = namespace.to_s if namespace.is_a?(Symbol)
      puts "add_namespace #{namespace} => #{handler}"
      puts @router.class
      @router.namespace(namespace, handler)
    else
      puts "add_namespace #{handler.class} => #{handler}"
      @router.namespace(handler.class, handler)
    end
  end

  def create_response(request)
    puts "Got Request Method: #{request['method']}, Params: #{request['params']}"
    super
  end

  def dispatch_request(method, params)
    method_name = method.to_s
    handler = @router.handler_for_method(method_name)
    puts "Got handler: #{handler} #{handler.class}"
    method_name = @router.strip_method_namespace(method_name)

#    if handler.nil?
#      puts "Handler not found"
#      raise Jimson::Server::Error::MethodNotFound.new(method)
#    end
#    unless handler.class.jimson_exposed_methods.include?(method_name)
#      puts "Method #{method_name} not found in #{handler.class.jimson_exposed_methods}"
#      raise Jimson::Server::Error::MethodNotFound.new(method)
#    end
#    unless handler.class.respond_to?(method_name)
#      puts "Handler does not respond"
#      raise Jimson::Server::Error::MethodNotFound.new(method)
#    end

    if params.nil?
      return handler.send(method_name)
    elsif params.is_a?(Hash)
      return handler.send(method_name, params)
    else
      return handler.class.send(method_name, *params)
    end
  end

end



server = RPCServer.new({:server => 'puma', :show_errors => true})
$db = DBManager.new
$modules = Plugins.new
$modules.add_plugin_source('./modules')
$modules.load_modules
$modules.init_modules
$modules.each do |name, moduleinstance|
  puts "Adding Namespace for Module #{name}"
  server.add_namespace(moduleinstance, name)
end
$plugins = Plugins.new
$plugins.add_plugin_source('./plugins')
$plugins.load_plugins
$plugins.each do |name, plugin|
  puts "Adding Namespace for Plugin #{name}"
  server.add_namespace(plugin, name)
end
server.start
