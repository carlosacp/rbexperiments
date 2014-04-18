class Class
  def included_modules
    @included_modules ||= []
  end
  alias_method :old_new, :new
  def new(*args, &block)
    obj = old_new(*args, &block)
    self.included_modules.each do |mod|
      mod.initialize(obj) if mod.respond_to?(:initialize)
    end
    obj
  end
end

module Initializable
  def self.included(base)
    base.extend ClassMethods
  end
  module ClassMethods
    def included(base)
      if base.class != Module
        base.included_modules << self
      end
    end
  end
end

module Configurable
  
  include Initializable
  
  def self.initialize(obj)
    obj.instance_variable_set(:@config, Configuration.new)
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

class SomeClass
  
  include Configurable

  #defaults...
  Configuration.configure do |config|
    config.some_config = "default_value"
  end

end

describe "Configuring" do
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
end