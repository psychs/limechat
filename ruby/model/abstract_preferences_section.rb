class Preferences
  class << self
    # A hash of all default values for the user defaults
    def default_values
      @default_values ||= {}
    end
    
    # Registers the default values with NSUserDefaults.standardUserDefaults
    # Called at the end of evaluating model/preferences.rb
    def register_default_values!
      NSUserDefaults.standardUserDefaults.registerDefaults(:pref => default_values)
    end
  end
  
  class AbstractPreferencesSection
    class << self
      # The key in the preferences that represents the section class.
      #
      #   Preferences::General.section_defaults_key # => :General
      def section_defaults_key
        @section_defaults_key ||= name.split('::').last.to_sym
      end
      
      # The default values defined by this section.
      def section_default_values
        Preferences.default_values[section_defaults_key] ||= {}
      end
      
      # Defines a reader and writer method for a user defaults key for this section.
      #
      #  # Defines #confirm_quit and #confirm_quit= and <tt>true</tt> as it's default value.
      #  defaults_accessor :confirm_quit, true
      def defaults_accessor(name, default_value)
        section_default_values[name] = default_value
        
        class_eval do
          define_method(name) do
            section_user_defaults[name].to_ruby
          end
          
          define_method("#{name}=") do |value|
            defaults = section_user_defaults.to_ruby
            defaults[name] = value
            self.section_user_defaults = defaults
            value
          end
        end
      end
    end
    
    # The reader method for the preferences for this section.
    def section_user_defaults
      NSUserDefaults.standardUserDefaults[:pref][self.class.section_defaults_key]
    end
    
    # The writer method for the preferences for this section.
    def section_user_defaults=(section_user_defaults)
      defaults = NSUserDefaults.standardUserDefaults[:pref].to_ruby.merge(self.class.section_defaults_key => section_user_defaults)
      NSUserDefaults.standardUserDefaults.setObject_forKey(defaults, :pref)
    end
  end
end