class Plugins < Hash

  def initialize
    @plugin_folders = []
  end

  def add_plugin_source(folder_path)
    @plugin_folders << File.absolute_path(folder_path)
  end

  def load_modules
    @plugin_folders.each do |folder_path|
      Dir[folder_path + '/*.rb'].each do |module_file_path|
        load_module(module_file_path)
      end
    end
  end

  def init_modules
    self.each_pair do |modulename, moduleinstance|
      puts "initializing Module #{modulename}"
      moduleinstance.init_module
    end
  end

  def load_plugins
    @plugin_folders.each do |folder_path|
      Dir[folder_path + '/*.rb'].each do |plugin_file_path|
        load_plugin(plugin_file_path)
      end
    end
  end

  def load_module(module_file_path)
    modulename = File.basename(module_file_path, '.*')
    modulename[0] = modulename[0].capitalize
    puts(" Will load #{modulename}")
    puts(" Modulepath: " + module_file_path)
    require module_file_path

    puts("loaded Module #{modulename}")
    self[modulename.to_sym] = Object.const_get(modulename).new
  end

  def load_plugin(plugin_file_path)
    pluginname = File.basename(plugin_file_path, '.*')
    pluginname[0] = pluginname[0].capitalize
    puts(" Will load #{pluginname}")
    puts(" Pluginpath: " + plugin_file_path)
    require plugin_file_path

    puts("loaded Plugin #{pluginname}")
    puts("loading Model for plugin #{pluginname}")
    model = $db.load_model(pluginname, plugin_file_path)
    self[pluginname.to_sym] = Object.const_get(pluginname)
    self[pluginname.to_sym].init_plugin(model)
  end

end

class Plugin

  def self.jimson_exposed_methods
    methods = self.methods.map(&:to_s) - Object.methods.map(&:to_s)
    methods << 'new'
    methods.delete('jimson_exposed_methods')
    methods
  end

  def self.method_missing(method_name, *args, &block)
    puts "No Method #{method_name} found" unless @model.methods.include?(method_name)
    @model.send(method_name, args) 
  end

end
