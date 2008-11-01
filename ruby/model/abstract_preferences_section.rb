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
      #  # Defines #confirm_quit and #confirm_quit= and <tt>true</tt> as it's default value.
      #  defaults_accessor :confirm_quit, true
      def defaults_accessor(name, default_value)
        key = "#{section_defaults_key}.#{name}"
        Preferences.default_values[key] = default_value
        
        class_eval do
          define_method(name) do
            NSUserDefaults.standardUserDefaults[key].to_ruby
          end
          
          define_method("#{name}=") do |value|
            NSUserDefaults.standardUserDefaults[key] = value
          end
        end
      end
    end
  end
end