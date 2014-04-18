module Configurable
  
  def self.included(base)
    base.class.__send__(:alias_method, :__configurable_original_new, :new)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def __configurable_initialize(obj)
      obj.instance_variable_set(:@config, Configuration.new)
    end
    def new(*args, &block)
      obj = __configurable_original_new(*args, &block)
      __configurable_initialize(obj)
      obj
    end    
    
    def configure
      yield @config
      @config
    end
    
  end
  
  def config
    @config
  end
  
end

class Configuration
  
  @@default_values = {}
    
  def initialize
    @@default_values.each do |name, value|
      self.class.__send__(:attr_accessor, name)
      instance_variable_set("@#{name}", value)
    end
  end

  def method_missing(sym, *args, &block)
    if sym.to_s.end_with? "=" and args.size == 1
      self.class.__send__(:attr_accessor, sym.to_s[0...-1])
      instance_variable_set("@#{sym.to_s[0...-1]}", args.first)
      @@default_values[sym.to_s[0...-1].to_sym] = args.first 
      return args.first            
    elsif args.size == 0
      return nil
    end
    super(sym, *args, &block)
  end

  def self.set_defaults defaults
    @@default_values = defaults
  end 
  
  def self.configure
    configuration = Configuration.new
    yield configuration
    self.set_defaults_from_configuration configuration
    configuration
  end
  
  def self.set_defaults_from_configuration(configuration)
    @@default_values.each { |name, value| @@default_values[name] = configuration.send(name) }
  end
  
end

Configuration.configure do |config|
  config.anything = "anything"
end

class SomeClass
  
  include Configurable

  #defaults...
  Configuration.configure do |config|
    config.some_config = "default_value"
  end

end

class AnotherClass
  
  include Configurable
  
  #defaults...
  configure do |config|
    config.anything = "something"
  end  
  
end

describe SomeClass do

  it "should have a default value if no config block is called" do
    a_instance = SomeClass.new
    a_instance.config.some_config.should == "default_value"
  end

  it "should handle global configuration" do
    Configuration.configure do |config|
      config.some_config = "other_value"
    end
    a_instance = SomeClass.new
    a_instance.config.some_config.should == "other_value"
  end
  
  it "should keep the value after late configuration" do
    a_instance = SomeClass.new
    Configuration.configure do |config|
      config.some_config = "another_different_value"
    end
    a_instance.config.some_config.should == "other_value"
  end
  
  it "should have a previous set default" do
    a_instance = SomeClass.new
    a_instance.config.anything.should == "anything"
  end 
end

describe AnotherClass do
  
  it "should override a previous set default" do
    a_instance = AnotherClass.new
    a_instance.config.anything.should == "something"
  end 
end