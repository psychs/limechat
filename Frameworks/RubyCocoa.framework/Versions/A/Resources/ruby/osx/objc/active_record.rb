# Copyright (c) 2006-2008, The RubyCocoa Project.
# Copyright (c) 2001-2006, FUJIMOTO Hisakuni.
# All Rights Reserved.
#
# RubyCocoa is free software, covered under either the Ruby's license or the 
# LGPL. See the COPYRIGHT file for more information.

require 'osx/cocoa'
begin
  # for testing old AR
  # require '/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/gems/1.8/gems/activesupport-1.4.2/lib/active_support.rb'
  # require '/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/gems/1.8/gems/activerecord-1.15.3/lib/active_record.rb'
  
  require 'active_record'
rescue LoadError
  msg = "ActiveRecord was not found, if you have it installed as a gem you have to require 'rubygems' before you require 'osx/active_record'"
  $stderr.puts msg
  raise LoadError, msg
end

# ---------------------------------------------------------
# Class additions
# ---------------------------------------------------------

class ActiveRecord::Base
  class << self
    alias_method :__inherited_before_proxy, :inherited
    def inherited(klass)
      proxy_klass = "#{klass.to_s}Proxy"
      unless klass.parent.local_constants.include?(proxy_klass)
        eval "class ::#{proxy_klass} < OSX::ActiveRecordProxy; end;"
        # FIXME: This leads to a TypeError originating from: oc_import.rb:618:in `method_added'
        # Object.const_set(proxy_klass, Class.new(OSX::ActiveRecordProxy))
      end
      __inherited_before_proxy(klass)
    end
  end
  
  # Returns a proxy for this instance.
  def to_activerecord_proxy
    if self.class.instance_variable_get(:@proxy_klass).nil?
      self.class.instance_variable_set(:@proxy_klass, Object.const_get("#{self.class.to_s}Proxy"))
    end
    @record_proxy ||= self.class.instance_variable_get(:@proxy_klass).alloc.initWithRecord(self)
  end
  alias_method :to_activerecord_proxies, :to_activerecord_proxy
end

class Array
  # Returns an array with proxies for all the original records in this array.
  def to_activerecord_proxies
    map { |rec| rec.to_activerecord_proxy }
  end
  alias_method :to_activerecord_proxy, :to_activerecord_proxies
  
  # Returns an array with all the original records for the proxies in this array.
  def original_records
    map { |rec| rec.original_record }
  end
end

module OSX
  
  # ---------------------------------------------------------
  # Subclasses of cocoa classes that add ActiveRecord support
  # ---------------------------------------------------------
  
  class ActiveRecordSetController < OSX::NSArrayController
    # First tries to destroy the record(s) then lets the super method do it's work.
    def remove(sender)
      super_remove(sender) if selectedObjects.all? {|proxy| proxy.destroy }
    end
    
    # Directly saves the new record.
    def newObject
      objectClass.class.create
    end
    
    # Sets up the ActiveRecordSetController for a given model and sets the content if it's specified.
    #
    # <tt>:model</tt> should be the model that we'll be handling.
    # <tt>:content</tt> is optional, if specified it should be an array with or without any proxies for the model that we're handling.
    def setup_for(options)
      raise ArgumentError, ":model was nil, expected a ActiveRecord::Base subclass" if options[:model].nil?
      # FIXME: not DRY, duplicated from ActiveRecord::Base#to_activerecord_proxy
      self.setObjectClass( Object.const_get("#{options[:model].to_s}Proxy") )
      self.setContent(options[:content]) unless options[:content].nil?
    end
  end
  
  class BelongsToActiveRecordSetController < ActiveRecordSetController
    # Doesn't save the record to the db in a belongs to association,
    # because it will automatically be saved by ActiveRecord when added to the collection.
    def newObject
      objectClass.class.alloc.init
    end
  end
  
  class ActiveRecordTableView < OSX::NSTableView
    require 'active_support/core_ext/string/inflections'
    include ActiveSupport::CoreExtensions::String::Inflections

    # <tt>:model</tt> should be the model class that you want to scaffold.
    # <tt>:bind_to</tt> should be the ActiveRecordSetController instance that you want the columns to be bound too.
    # <tt>:except</tt> can be either a string or an array that says which columns should not be displayed.
    # <tt>:validates_immediately</tt> set this to +true+ to add validation to every column. Defaults to +false+.
    #
    #   ib_outlets :customersTableView, :customersRecordSetController
    #  
    #   def awakeFromNib
    #     @customersTableView.scaffold_columns_for :model => Customer, :bind_to => @customersRecordSetController, :validates_immediately => true, :except => "id"
    #   end
    #
    # You can also pass it a block which will yield 2 objects for every column, namely +table_column+ which is the new NSTableColumn
    # and +column_opyions+ which is a hash that can be used to set additional options for the binding.
    #
    #   ib_outlets :customersTableView, :customersRecordSetController
    #  
    #   def awakeFromNib
    #     @customersTableView.scaffold_columns_for :model => Customer, :bind_to => @customersRecordSetController do |table_column, column_options|
    #       p table_column
    #       p column_options
    #       column_options['NSValidatesImmediately'] = true
    #     end
    #   end
    def scaffold_columns_for(options)
      raise ArgumentError, ":model was nil, expected a ActiveRecord::Base subclass" if options[:model].nil?
      raise ArgumentError, ":bind_to was nil, expected an instance of ActiveRecordSetController" if options[:bind_to].nil?
      options[:except] ||= []
      options[:validates_immediately] ||= false
      
      # if there are any columns already, first remove them.
      cols = self.tableColumns
      if cols.count > 0
        # we create a temporary array because we do not want to mutate the
        # original one during the enumeration
        tmpCols = OSX::NSArray.arrayWithArray(cols)
        tmpCols.each { |column| self.removeTableColumn(column) }
      end
      
      options[:model].column_names.each do |column_name|
        # skip columns
        next if options[:except].include?(column_name)
        # setup new table column
        table_column = OSX::NSTableColumn.alloc.init
        table_column.setIdentifier(column_name)
        table_column.headerCell.setStringValue(column_name.titleize)
        # create a hash that will hold the options that will be passed as options to the bind method
        column_options = {}
        column_options['NSValidatesImmediately'] = options[:validates_immediately]
        
        # FIXME: causes a bus error on my machine...
        yield(table_column, column_options) if block_given?
        
        # set the binding
        table_column.bind_toObject_withKeyPath_options(OSX::NSValueBinding, options[:bind_to], "arrangedObjects.#{column_name}", column_options)
        # and add it to the table view
        self.addTableColumn(table_column)
      end
    end
  end
  
  class ActiveRecordProxy < OSX::NSObject
    
    # class methods
    class << self
      # Use this class method to set any filters you need when a specific value for a key is requested.
      # You can pass it a block, or a hash that contains either the key:
      # - <tt>:return</tt> which needs an array that holds the class to be instantiated as the first element
      # and the method to be called if the data isn't nil as the second element.
      # If the data is nil the class will simply be instantiated with the normal alloc.init call.
      # - <tt>:call</tt> which needs the method that it should call. When the method is called the data is sent as the argument.
      #
      #   class EmailProxy < OSX::ActiveRecordProxy
      #     # on_get filter with: block
      #     on_get :body do |content|
      #       content ||= 'I'm so empty'
      #       OSX::NSAttributedString.alloc.initWithString(content)
      #     end
      # 
      #     # on_get filter with: return
      #     on_get :subject, :return => [OSX::NSAttributedString, :initWithString]
      # 
      #     # on_get filter with: call
      #     on_get :address, :call => :nsattributed_string_from_address
      #     # and the method to be called
      #     def nsattributed_string_from_address(address)
      #       address ||= 'Emptier than this isn't possible'
      #       OSX::NSAttributedString.alloc.initWithString(address)
      #     end
      #   end
      def on_get(key, options={}, &block)
        @on_get_filters ||= {}
        @on_get_filters[key.to_sym] = ( block.nil? ? options : block )
      end
      
      # This find class method passes the message on to the model, but it will return proxies for the returned records
      def find(*args)
        model_class.find(*args).to_activerecord_proxies
      end
      
      # This method_missing class method passes the find_by_ message on to the model, but it will return proxies for the returned records
      def method_missing(method, *args)
        if method.to_s.index('find_by_') == 0
          model_class.send(method, *args).to_activerecord_proxies
        else
          super
        end
      end
      
      # Returns the model class for this proxy
      def model_class
        @model_class ||= Object.const_get(self.to_s[0..-6])
      end
      
      def create(attributes = {})
        alloc.initWithAttributes(attributes)
      end
    end
    
    # Creates a new record and returns a proxy for it.
    def init
      if super_init
        @record = self.record_class.send(:new) unless @record
        define_record_methods! unless self.class.instance_variable_get(:@record_methods_defined)
        self
      end
    end
    
    # Takes an existing record as an argument and returns a proxy for it.
    def initWithRecord(record)
      @record = record
      init
    end
    
    # Creates a new record with the given attributes and returns a proxy for it.
    def initWithAttributes(attributes)
      @record = record_class.send(:new, attributes)
      return nil unless @record.save
      init
    end
    
    # Returns the model class for this proxy
    def record_class
      self.class.model_class
    end
  
    # Returns an Array of all the available methods on the corresponding record object
    def record_methods
      @record.methods
    end
  
    # Returns the corresponding record object
    def to_activerecord
      @record
    end
    # Returns the corresponding record object
    def original_record
      @record
    end
    
    # Useful inspect method for use as: p(my_proxy)
    def inspect
      @record.inspect.sub(/#{record_class}/, "#{self.class.name.to_s} proxy_object_id: #{self.object_id} record_object_id: #{@record.object_id}")
    end
    
    # Compare two ActiveRecord proxies. They are compared by the record.
    def ==(other)
      if self.class == other.class
        self.original_record == other.original_record
      else
        super
      end
    end
    
    # Returns +true+ if the given key is an association, otherwise returns +false+
    def is_association?(key)
      key_sym = key.to_s.to_sym
      @record.class.reflect_on_all_associations.each { |assoc| return true if assoc.name == key_sym }
      false
    end
  
    # KVC stuff
    
    # Get the filter for a given key if it exists.
    def on_get_filter_for_key(key)
      filters = self.class.instance_variable_get(:@on_get_filters)
      filters[key.to_sym] unless filters.nil?
    end
    
    # This method is called by the object that self is bound to,
    # if the requested key is a association return proxies for the records.
    def rbValueForKey(key)
      if is_association?(key)
        @record.send(key.to_s.to_sym).to_activerecord_proxies
      else
        if filter = self.on_get_filter_for_key(key)
          if filter.is_a?(Hash)
            case filter.keys.first
            when :return
              klass, method = filter[:return]
              data = @record[key.to_s]
              return (data.nil? ? klass.alloc.init : klass.alloc.send(method.to_sym, data))
            when :call # callback method
              send(filter[:call], @record[key.to_s])
            end
          elsif filter.is_a?(Proc)
            filter.call(@record[key.to_s])
          end
        else
          # no filter, so simply return the data
          @record[key.to_s]
        end
      end
    end
  
    # This method is called by the object that self is bound to,
    # it's called when a update has occured.
    def rbSetValue_forKey(value, key)
      if is_association? key
        # we are dealing with an association (only has_many for now)
        if @record.send(key.to_s.to_sym).length < value.to_a.length
          # add the newest record to the has_many association of the @record
          return true if (@record.send(key.to_s.to_sym) << value.to_a.last.to_activerecord)
        else
          # reload the children to reflect the changes deletion of records
          @record.reload
          return true
        end
      else
        @record[key.to_s] = value.to_ruby rescue nil
        return @record.save
      end
      return false
    end
  
    # This method is called by the object that self is bound to,
    # it passes the value on to the record object and returns the validation result.
    def validateValue_forKeyPath_error(value, key, error)
      original_value = @record[key.to_s]
      @record[key.to_s] = value[0].to_s
      @record.valid?
      
      # we only want to check if the value for this attribute is valid and not every attribute
      return true if @record.errors[key.to_s].nil?

      @record[key.to_s] = original_value
      # create a error message for each validation error on this attribute
      error_msg = ''
      @record.errors[key.to_s].each do |err|
        error_msg += "#{self.record_class} #{key.to_s} #{err}\n"
      end
      # construct the NSError object
      error.assign( OSX::NSError.alloc.initWithDomain_code_userInfo( OSX::NSCocoaErrorDomain, -1, { OSX::NSLocalizedDescriptionKey => error_msg } ) )
      false
    end

    private
    
    def define_record_methods!
      # define all the record attributes getters and setters
      @record.attribute_names.each do |m|
        self.class.class_eval do
          define_method(m) do
            #return @record.send(m)
            return rbValueForKey(m.to_s)
          end
          sym = "#{m}=".to_sym
          define_method(sym) do |*args|
            return @record.send(sym, *args)
          end
        end
      end
      # define the normal instance methods of the record
      (@record.methods - self.methods).each do |m|
        next if m == 'initialize'
        self.class.class_eval do
          define_method(m) do |*args|
            if is_association?(m)
              return rbValueForKey(m)
            else
              return @record.send(m, *args)
            end
          end
        end
      end
      self.class.instance_variable_set(:@record_methods_defined, true)
    end
  end

  # ---------------------------------------------------------
  # Extra support classes/modules
  # ---------------------------------------------------------
  
  module ActiveRecordConnector
    def connect_to_sqlite(dbfile, options = {})
      options[:log] ||= false

      if options[:log]
        ActiveRecord::Base.logger = Logger.new($stderr)
        ActiveRecord::Base.colorize_logging = false
      end

      # Connect to the database
      ActiveRecord::Base.establish_connection({
        :adapter => 'sqlite3',
        :dbfile => dbfile
      })
    end
    module_function :connect_to_sqlite
    
    # Connect to an SQLite database stored in the applications support directory ~/USER/Library/Application Support/APP/APP.sqlite.
    # <tt>:always_migrate</tt> Always run migrations when this method is invoked, false by default.
    # <tt>:migrations_dir</tt> The directory where migrations are stored, migrate/ by default.
    # <tt>:log</tt> Log database activity, false by default.
    #
    #   ActiveRecordConnector.connect_to_sqlite_in_application_support :log => true
    #
    # If you run this for the first time and haven't already created a migration to create your database
    # tables, etc., you'll need to force the migration if :always_migrate isn't enabled.
    def connect_to_sqlite_in_application_support(options = {})
      options[:always_migrate] ||= false
      options[:migrations_dir] ||= 'migrate/'

      dbfile = File.join(self.get_app_support_path, "#{self.get_app_name}.sqlite")
      # connect
      self.connect_to_sqlite(dbfile, options)
      # do any necessary migrations
      if not File.exists?(dbfile) or options[:always_migrate]
        migrations_dir = File.join(OSX::NSBundle.mainBundle.resourcePath.fileSystemRepresentation.to_s, options[:migrations_dir])
        # do a migration to the latest version
        ActiveRecord::Migrator.migrate(migrations_dir, nil)
      end
    end
    module_function :connect_to_sqlite_in_application_support
    
    def get_app_name
      OSX::NSBundle.mainBundle.bundleIdentifier.to_s.scan(/\w+$/).first
    end
    module_function :get_app_name
    
    def get_app_support_path
      # get the path to the ~/Library/Application Support/ directory
      user_app_support_path = File.join(OSX::NSSearchPathForDirectoriesInDomains(OSX::NSLibraryDirectory, OSX::NSUserDomainMask, true)[0].to_s, "Application Support")
      # get the complete path to the directory that will hold the files for this app.
      # e.g.: ~/Library/Application Support/SomeApp/
      path_to_this_apps_app_support_dir = File.join(user_app_support_path, self.get_app_name)
      # and create it if necessary
      unless File.exists?(path_to_this_apps_app_support_dir)
        require 'fileutils'
        FileUtils.mkdir_p(path_to_this_apps_app_support_dir)
      end
      return path_to_this_apps_app_support_dir
    end
    module_function :get_app_support_path
  end

end
