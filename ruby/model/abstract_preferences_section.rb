require 'singleton'

class Preferences
  class << self
    # A hash of all default values for the user defaults
    def default_values
      @default_values ||= {}
    end
    
    # Registers the default values with NSUserDefaults.standardUserDefaults
    # Called at the end of evaluating model/preferences.rb
    def register_default_values!
      NSUserDefaults.standardUserDefaults.registerDefaults(default_values)
    end
  end
  
  class AbstractPreferencesSection
    include Singleton
    
    class << self
      # The key in the preferences that represents the section class.
      #
      #   Preferences::General.section_defaults_key # => "Preferences.General"
      def section_defaults_key
        @section_defaults_key ||= name.gsub('::', '.')
      end
      
      # Defines a reader and writer method for a user defaults key for this section.
      #
      #   # Defines #confirm_quit and #confirm_quit= and <tt>true</tt> as it's default value.
      #   defaults_accessor :confirm_quit, true
      def defaults_accessor(name, default_value)
        key_path = "#{section_defaults_key}.#{name}"
        Preferences.default_values[key_path] = default_value
        
        class_eval do
          define_method(name) do
            NSUserDefaults.standardUserDefaults[key_path].to_ruby
          end
          
          define_method("#{name}=") do |value|
            NSUserDefaults.standardUserDefaults[key_path] = value
          end
          
          if default_value == true || default_value == false
            alias_method "#{name}?", name
          end
        end
        
        key_path
      end
      
      # Besides defining a reader and writer method via defaults_accessor,
      # it also defines a reader method which returns an array of strings
      # wrapped in KVO compatible string wrappers.
      #
      # The name of the wrapper class is defined by <tt>wrapper_class_name</tt>
      # and can be used as the `Class Name' of a NSArrayController.
      # The wrapper exposes `string' as a KVC accessor to which a NSTableColumn can be bound.
      #
      #   # Defines #highlight_words, #highlight_words=, and #highlight_words_wrapped
      #   string_array_defaults_accessor :highlight_words, [], 'HighlightWordWrapper'
      def string_array_defaults_accessor(name, default_value, wrapper_class_name)
        wrapper = eval("class ::#{wrapper_class_name} < StringArrayWrapper; self end")
        wrapper.key_path = defaults_accessor(name, default_value)
        
        class_eval do
          define_method("#{name}_wrapped") do
            ary = []
            send(name).each_with_index { |string, index| ary << wrapper.alloc.initWithString_index(string, index) }
            ary
          end
        end
      end
    end
    
    def observe(name, observer)
      key_path = "values.#{self.class.section_defaults_key}.#{name}"
      NSUserDefaultsController.sharedUserDefaultsController.
        addObserver_forKeyPath_options_context(observer, key_path, NSKeyValueObservingOptionNew, nil)
    end
  end
  
  class StringArrayWrapper < OSX::NSObject
    class << self
      attr_accessor :key_path
      
      def array
        NSUserDefaults.standardUserDefaults[key_path].to_ruby
      end
      
      def array=(array)
        NSUserDefaults.standardUserDefaults[key_path] = array
      end
      
      def destroy(klass, new_wrappers)
        # Set the new correct indices on the remaining wrappers
        new_wrappers.each_with_index do |wrapper, new_index|
          wrapper.index = new_index
        end
        
        # Assign the new result array of strings
        klass.array = new_wrappers.map { |wrapper| wrapper.string }
      end
    end
    
    kvc_accessor :string
    attr_accessor :index
    
    def initWithString_index(string, index)
      if init
        @string, @index = string, index
        self
      end
    end
    
    def array
      self.class.array
    end
    
    def array=(array)
      self.class.array = array
    end
    
    def string=(string)
      @string = string
      set_string!
    end
    
    def set_string!
      if @index
        ary = array
        ary[@index] = string
        self.array = ary
      else
        ary = array
        ary << @string
        self.array = ary
        @index = ary.length - 1
      end
    end
    
    def inspect
      "#<#{self.class.name}:#{object_id} string=\"#{@string}\" key_path=\"#{self.class.key_path}\" index=\"#{@index}\">"
    end
  end
  
  module StringArrayWrapperHelper
    def string_array_kvc_wrapper_accessor(name, path_to_eval_to_object)
      kvc_accessor(name)
      
      class_eval %{
        def #{name}
          @#{name} ||= #{path_to_eval_to_object}_wrapped
        end
        
        def #{name}=(new_wrappers)
          if new_wrappers.length < #{name}.length
            Preferences::StringArrayWrapper.destroy(#{name}.first.class, new_wrappers)
          end
          @#{name} = new_wrappers
        end
      }, __FILE__, __LINE__
    end
  end
  
  module KVOCallbackHelper
    # We need to actually define the method on the class because otherwise the method is not
    # resolved at runtime, probably a bug in RubyCocoa.
    def self.included(klass)
      klass.class_eval do
        def observeValueForKeyPath_ofObject_change_context(key_path, observed, change, context)
          value_key_path = key_path.sub(/^values\./, '')
          callback_method = "#{key_path.split('.').last}_changed"
          send(callback_method, NSUserDefaults.standardUserDefaults[value_key_path].to_ruby)
        end
      end
    end
  end
end