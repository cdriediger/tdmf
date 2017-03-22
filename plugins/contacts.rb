class Contacts < Plugin

  def self.init_plugin(model)
    @model = model
  end

  def self.test_method
    "1,2,3"
  end

end
