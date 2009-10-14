# Copyright (c) 2006-2008, The RubyCocoa Project.
# Copyright (c) 2001-2006, FUJIMOTO Hisakuni.
# All Rights Reserved.
#
# RubyCocoa is free software, covered under either the Ruby's license or the 
# LGPL. See the COPYRIGHT file for more information.

require 'osx/objc/oc_wrapper'

module OSX

  FRAMEWORK_PATHS = [
    '/System/Library/Frameworks',
    '/Library/Frameworks'
  ]

  SIGN_PATHS = [
    '/System/Library/BridgeSupport', 
    '/Library/BridgeSupport'
  ]

  PRE_SIGN_PATHS = 
    if path = ENV['BRIDGE_SUPPORT_PATH']
      path.split(':')
    else
      []
    end

  FRAMEWORK_PATHS.concat(RUBYCOCOA_FRAMEWORK_PATHS)

  if path = ENV['HOME']
    FRAMEWORK_PATHS << File.join(ENV['HOME'], 'Library', 'Frameworks')
    SIGN_PATHS << File.join(ENV['HOME'], 'Library', 'BridgeSupport')
  end

  # A name-to-path cache for the frameworks we support that are buried into umbrella frameworks.
  QUICK_FRAMEWORKS = {
    'CoreGraphics' => '/System/Library/Frameworks/ApplicationServices.framework/Frameworks/CoreGraphics.framework',
    'PDFKit' => '/System/Library/Frameworks/Quartz.framework/Frameworks/PDFKit.framework',
    'QuartzComposer' => '/System/Library/Frameworks/Quartz.framework/Frameworks/QuartzComposer.framework',
    'ImageKit' => '/System/Library/Frameworks/Quartz.framework/Frameworks/ImageKit.framework'
  }

  def _bundle_path_for_framework(framework)
    if framework[0] == ?/
      [OSX::NSBundle.bundleWithPath(framework), framework]
    elsif path = QUICK_FRAMEWORKS[framework]
      [OSX::NSBundle.bundleWithPath(path), path]
    else
      path = FRAMEWORK_PATHS.map { |dir| 
        File.join(dir, "#{framework}.framework") 
      }.find { |path| 
        File.exist?(path) 
      }
      if path
        [OSX::NSBundle.bundleWithPath(path), path]
      end
    end
  end
  module_function :_bundle_path_for_framework
  
  # The OSX::require_framework method imports Mac OS X frameworks and uses the
  # BridgeSupport metadata to add Ruby entry points for the framework's Classes,
  # methods, and Constants into the OSX module.
  #
  # The framework parameter is a reference to the framework that should be
  # imported.  This may be a full path name to a particular framework, a shortcut,
  # or a framework name.  The shortcuts are the keys listed in the
  # <tt>QUICK_FRAMEWORKS</tt> hash.
  #
  # If a framework name (with no path) is given, then the method searches a number
  # of directories.  Those directories (in search order) are:
  #   1.  /System/Library/Frameworks
  #   2.  /Library/Frameworks
  #   3.  Any directories in the RUBYCOCOA_FRAMEWORK_PATHS array, if defined
  #   4.  ENV['HOME']/Library/Frameworks, if the HOME environment variable is defined
  #
  # When using the search paths, the <tt>.framework</tt> file type extension should
  # be omitted from the framework name passed to the method.
  #
  # If the method loads the framework successfully, it returns <tt>true</tt>.
  # If the framework was already loaded the method returns <tt>false</tt>.
  # If the method is unable to locate, or unable to load the framework then it
  # raises an <tt>ArgumentError</tt>.
  def require_framework(framework)
    return false if framework_loaded?(framework)
    bundle, path = _bundle_path_for_framework(framework)
    bundle.oc_load
    if not bundle.isLoaded? then
      raise ArgumentError, "Can't load framework '#{framework}'" 
    end
    load_bridge_support_signatures(path)
    return true
  end
  module_function :require_framework

  def framework_loaded?(framework)
    bundle, path = _bundle_path_for_framework(framework)
    unless bundle.nil?
      loaded = bundle.isLoaded
      if loaded then
        load_bridge_support_signatures(path)
      else
        # CoreFoundation/Foundation are linked at built-time.
        id = bundle.bundleIdentifier
        loaded = (id.isEqualToString('com.apple.CoreFoundation') or 
                  id.isEqualToString('com.apple.Foundation'))
      end
      loaded
    else
      raise ArgumentError, "Can't locate framework '#{framework}'"
    end
  end
  module_function :framework_loaded?

  def __load_bridge_support_file__(dir, framework_name)
    @bridge_support_signatures_loaded_marks ||= {}
    return true if @bridge_support_signatures_loaded_marks[framework_name]
    bs = File.join(dir, framework_name + '.bridgesupport')
    pbs = File.join(dir, framework_name + 'Private.bridgesupport')
    if File.exist?(bs) or File.exist?(pbs)
      # Load the .dylib first (if any).
      dylib = File.join(dir, framework_name + '.dylib')
      OSX.load_bridge_support_dylib(dylib) if File.exist?(dylib) 

      # Then the regular metadata file.
      OSX.load_bridge_support_file(bs) if File.exist?(bs)
    
      # And finally the private metadata file (if any).
      OSX.load_bridge_support_file(pbs) if File.exist?(pbs)
      return @bridge_support_signatures_loaded_marks[framework_name] = true
    end
    return false
  end
  module_function :__load_bridge_support_file__

  def load_bridge_support_signatures(framework)
    # First, look into the pre paths.  
    fname = framework[0] == ?/ ? File.basename(framework, '.framework') : framework
    PRE_SIGN_PATHS.each { |dir| return true if __load_bridge_support_file__(dir, fname) }

    # A path to a framework, let's search for a BridgeSupport file inside the Resources folder.
    if framework[0] == ?/
      path = File.join(framework, 'Resources', 'BridgeSupport')
      return true if __load_bridge_support_file__(path, fname)
      framework = fname
    end
    
    # Let's try to localize the framework and see if it contains the metadata.
    FRAMEWORK_PATHS.each do |dir|
      path = File.join(dir, "#{framework}.framework")
      if File.exist?(path)
        path = File.join(path, 'Resources', 'BridgeSupport')
        return true if __load_bridge_support_file__(path, fname)
      end
    end

    # Try the app/bundle specific and RubyCocoa.framework metadata directories.
    RUBYCOCOA_SIGN_PATHS.each do |path| 
      if File.exist?(path) then
        return true if __load_bridge_support_file__(path, fname) 
      end
    end

    # We can still look into the general metadata directories. 
    SIGN_PATHS.each { |dir| return true if __load_bridge_support_file__(dir, fname) } 

    # Damnit!
    warn "Can't find signatures file for #{framework}" if OSX._debug?
    return false
  end
  module_function :load_bridge_support_signatures

  # Load C constants/classes lazily.
  def self.const_missing(c)
    begin
      OSX::import_c_constant(c)
    rescue LoadError
      (OSX::ns_import(c) or raise NameError, "uninitialized constant #{c}")
    end
  end

  def self.included(m)
    if m.respond_to? :const_missing
      m.module_eval do
        class <<self
          alias_method :_osx_const_missing_prev, :const_missing
          def const_missing(c)
            begin
              OSX.const_missing(c)
            rescue NameError
              _osx_const_missing_prev(c)
            end
          end
        end
      end
    else
      m.module_eval do
        def self.const_missing(c)
          OSX.const_missing(c)
        end
      end
    end
  end
  
  # Load the foundation frameworks.
  OSX.load_bridge_support_signatures('CoreFoundation')
  OSX.load_bridge_support_signatures('Foundation')

  # create Ruby's class for Cocoa class,
  # then define Constant under module 'OSX'.
  def ns_import(sym)
    if not OSX.const_defined?(sym)
      NSLog("importing #{sym}...") if OSX._debug?
      klass = if clsobj = NSClassFromString(sym)
        if rbcls = class_new_for_occlass(clsobj)
          OSX.const_set(sym, rbcls)
        end
      end
      NSLog("importing #{sym}... done (#{klass.ancestors.join(' -> ')})") if (klass and OSX._debug?)
      return klass
    end
  end
  module_function :ns_import

  # create Ruby's class for Cocoa class
  def class_new_for_occlass(occls)
    superclass = _objc_lookup_superclass(occls)
    klass = Class.new(superclass)
    klass.class_eval do
      if superclass == OSX::ObjcID
        include OCObjWrapper 
        self.extend OCClsWrapper
      end
      @ocid = occls.__ocid__.to_i
    end
    if superclass == OSX::ObjcID
      def klass.__ocid__() @ocid end
      def klass.to_s() name end
      def klass.inherited(subklass) subklass.ns_inherited() end
    end
    return klass
  end
  module_function :class_new_for_occlass 
 
  def _objc_lookup_superclass(occls)
    occls_superclass = occls.oc_superclass
    if occls_superclass.nil? or occls_superclass.__ocid__ == occls.__ocid__ 
      OSX::ObjcID
    elsif occls_superclass.is_a?(OSX::NSProxy) or occls_superclass.__ocid__ == OSX::NSProxy.__ocid__
      OSX::NSProxy
    else
      begin
        OSX.const_get(occls_superclass.to_s.to_sym) 
      rescue NameError
        # some ObjC internal class cannot become Ruby constant
        # because of prefix '%' or '_'
        if occls.__ocid__ != occls_superclass.__ocid__
          OSX._objc_lookup_superclass(occls_superclass)
        else
          OSX::ObjcID # root class of ObjC
        end
      end
    end
  end
  module_function :_objc_lookup_superclass

  module NSBehaviorAttachment

    ERRMSG_FOR_RESTRICT_NEW = "use 'alloc.initXXX' to instantiate Cocoa Object"

    # restrict creating an instance by Class#new, unless the Objective-C class 
    # really responds to the new selector.
    def new
      if ocm_responds?(:new)
        objc_send(:new)
      else
        raise ERRMSG_FOR_RESTRICT_NEW
      end
    end

    # initializer for definition of a derived class of a class on
    # Objective-C World.
    def ns_inherited()
      return if ns_inherited?
      kls_name = self.name.split('::')[-1]
      if kls_name
        spr_name = superclass.name.split('::')[-1]
        occls = OSX.objc_derived_class_new(self, kls_name, spr_name)
        self.instance_eval { @ocid = occls.__ocid__.to_i }
        OSX::BundleSupport.bind_class_with_current_bundle(self) 
      end
      @inherited = true
    end

    def ns_inherited?
      return defined?(@inherited) && @inherited
    end

    # declare to override instance methods of super class which is
    # defined by Objective-C.
    def ns_overrides(*args)
      warn "#{caller[0]}: ns_overrides is no longer necessary, should not be called anymore and will be removed in a next release. Please update your code to not use it."
    end
    alias_method :ns_override,  :ns_overrides
    alias_method :ib_override,  :ns_overrides
    alias_method :ib_overrides, :ns_overrides

    # declare write-only attribute accessors which are named IBOutlet
    # in the Objective-C world.
    def ib_outlets(*args)
      attr_writer(*args)
    end
    alias_method :ib_outlet, :ib_outlets

    def ns_outlets(*args)
      warn "#{caller[0]}:: ns_outlet(s) is deprecated, and will be removed in a next release. Please use ib_outlet(s) instead."
      ib_outlets(*args)
    end
    alias_method :ns_outlet,  :ns_outlets

    # declare a IBAction method. if given a block, it mean the
    # implementation of the action.
    def ib_action(name, &blk)
      define_method(name, blk) if block_given?
    end

    def _ns_behavior_method_added(sym, class_method)
      return if OSX._ignore_ns_override
      sel = sym.to_s.gsub(/([^_])_/, '\1:') 
      arity = if defined?(@__imported_arity) and @__imported_arity != nil \
              and RUBY_VERSION < "1.8.5"
        # This is a workaround for a Ruby 1.8.2 issue, the real arity is 
        # provided by _register_method. 
        @__imported_arity
      else
        m = class_method ? method(sym) : instance_method(sym)
        m.arity
      end
      sel << ':' if arity > 0 and /[^:]\z/ =~ sel
      mtype = nil
      if _ns_enable_override?(sel, class_method) or
      mtype = OSX.lookup_informal_protocol_method_type(sel, class_method)
        expected_arity = sel.scan(/:/).length
        if expected_arity != arity
          raise RuntimeError, "Cannot override Objective-C method '#{sel}' with Ruby method ##{sym}, they should both have the same number of arguments. (expected arity #{expected_arity}, got #{arity})"
        end
        OSX.objc_class_method_add(self, sel, class_method, mtype)
      end
    end

    def _ns_enable_override?(sel, class_method)
      ns_inherited? and (class_method ? self.objc_method_type(sel) : self.objc_instance_method_type(sel))
    end

    def _no_param_method?(typefmt)
      if typefmt[0] == ?{
        count = 1
        i = 0
        while count > 0 and i = typefmt.index(/[{}]/, i + 1)
          case typefmt[i]
          when ?{; count += 1
          when ?}; count -= 1
          end
        end
        raise ArgumentError, "illegal type encodings" unless i
        typefmt[i+1..-1] == '@:'
      else
        typefmt.index('@:') == typefmt.length - 2
      end
    end

    def _objc_export(name, types, class_method)
      typefmt = _types_to_typefmt(types)
      name = name.to_s
      name = name[0].chr << name[1..-1].gsub(/_/, ':')
      name << ':' if name[-1] != ?: and not _no_param_method?(typefmt)
      OSX.objc_class_method_add(self, name, class_method, typefmt)
    end

    def def_objc_method(name, types, &blk)
      if block_given? then
        objc_method(name, types, &blk) 
      else
        raise ArgumentError, "block for method implementation expected"
      end
    end

    def objc_method(name, types=['id'], &blk)
      define_method(name, blk) if block_given?
      _objc_export(name, types, false)
    end

    def objc_class_method(name, types=['id'])
      _objc_export(name, types, true)
    end

    def objc_export(name, types)
      warn "#{caller[0]}: objc_export is deprecated, and will be removed in a next release. please use objc_method instead."
      objc_method(name, types)
    end

    def objc_alias_method(new, old)
      new_sel = new.to_s.gsub(/([^_])_/, '\1:')
      old_sel = old.to_s.gsub(/([^_])_/, '\1:')
      _objc_alias_method(new, old)
    end

    def objc_alias_class_method(new, old)
      new_sel = new.to_s.gsub(/([^_])_/, '\1:')
      old_sel = old.to_s.gsub(/([^_])_/, '\1:')
      _objc_alias_class_method(new, old)
    end

    # TODO: support more types such as pointers...
    OCTYPES = {
      :id       => '@',
      :class    => '#',
      :BOOL     => 'c',
      :char     => 'c',
      :uchar    => 'C',
      :short    => 's',
      :ushort   => 'S',
      :int      => 'i',
      :uint     => 'I',
      :long     => 'l',
      :ulong    => 'L',
      :float    => 'f',
      :double   => 'd',
      :bool     => 'B',
      :void     => 'v',
      :selector => ':',
      :sel      => ':',
      :longlong => 'q',
      :ulonglong => 'Q',
      :cstr     => '*',
    }
    def _types_to_typefmt(types)
      return types.strip if types.is_a?(String)
      raise ArgumentError, "Array or String (as type format) expected (got #{types.klass} instead)" unless types.is_a?(Array)
      raise ArgumentError, "Given types array should have at least an element" unless types.size > 0
      octypes = types.map do |type|
        if type.is_a?(Class) and type.ancestors.include?(OSX::Boxed)
          type.encoding
        else
          type = type.strip.intern unless type.is_a?(Symbol)
          octype = OCTYPES[type]
          raise "Invalid type (got '#{type}', expected one of : #{OCTYPES.keys.join(', ')}, or a boxed class)" if octype.nil?
          octype
        end
      end
      octypes[0] + '@:' + octypes[1..-1].join
    end

  end       # module OSX::NSBehaviorAttachment

  module NSKVCAccessorUtil
    private

    def kvc_internal_setter(key)
      return '_kvc_internal_' + key.to_s + '=' 
    end

    def kvc_setter_wrapper(key)
      return '_kvc_wrapper_' + key.to_s + '=' 
    end
  end       # module OSX::NSKVCAccessorUtil

  module NSKeyValueCodingAttachment
    include NSKVCAccessorUtil

    # invoked from valueForUndefinedKey: of a Cocoa object
    def rbValueForKey(key)
      if m = kvc_getter_method(key.to_s)
        return send(m)
      else
        kvc_accessor_notfound(key)
      end
    end

    # invoked from setValue:forUndefinedKey: of a Cocoa object
    def rbSetValue_forKey(value, key)
      if m = kvc_setter_method(key.to_s)
        send(m, value)
      else
        kvc_accessor_notfound(key)
      end
    end

    private
    
    # find accesor for key-value coding
    # "key" must be a ruby string

    def kvc_getter_method(key)
      [key, key + '?'].each do |m|
        return m if respond_to? m
      end
      return nil # accessor not found
    end
 
    def kvc_setter_method(key)
      [kvc_internal_setter(key), key + '='].each do |m|
        return m if respond_to? m
      end
      return nil
    end

    def kvc_accessor_notfound(key)
      fmt = '%s: this class is not key value coding-compliant for the key "%s"'
      raise sprintf(fmt, self.class, key.to_s)
    end

  end       # module OSX::NSKeyValueCodingAttachment

  module NSKVCBehaviorAttachment
    include NSKVCAccessorUtil

    def kvc_reader(*args)
      attr_reader(*args)
    end

    def kvc_writer(*args)
      args.flatten.each do |key|
	next if method_defined?(kvc_setter_wrapper(key))
        setter = key.to_s + '='
        attr_writer(key) unless method_defined?(setter)
        alias_method kvc_internal_setter(key), setter
        self.class_eval <<-EOE_KVC_WRITER,__FILE__,__LINE__+1
          def #{kvc_setter_wrapper(key)}(value)
	    if self.class.automaticallyNotifiesObserversForKey('#{key.to_s}')
	      willChangeValueForKey('#{key.to_s}')
	      send('#{kvc_internal_setter(key)}', value)
	      didChangeValueForKey('#{key.to_s}')
	    else
	      send('#{kvc_internal_setter(key)}', value)
	    end
          end
        EOE_KVC_WRITER
        alias_method setter, kvc_setter_wrapper(key)
      end
    end

    def kvc_accessor(*args)
      kvc_reader(*args)
      kvc_writer(*args)
    end

    def kvc_depends_on(keys, *dependencies)
      dependencies.flatten.each do |dependentKey|
        setKeys_triggerChangeNotificationsForDependentKey(Array(keys), dependentKey)
      end
    end
 
    # define accesor for keys defined in Cocoa, 
    # such as NSUserDefaultsController and NSManagedObject
    def kvc_wrapper(*keys)
      kvc_wrapper_reader(*keys)
      kvc_wrapper_writer(*keys)
    end

    def kvc_wrapper_reader(*keys)
      keys.flatten.compact.each do |key|
        class_eval <<-EOE_KVC_WRAPPER,__FILE__,__LINE__+1
          def #{key}
            valueForKey("#{key}")
          end
        EOE_KVC_WRAPPER
      end
    end

    def kvc_wrapper_writer(*keys)
      keys.flatten.compact.each do |key|
        class_eval <<-EOE_KVC_WRAPPER,__FILE__,__LINE__+1
          def #{key}=(val)
            setValue_forKey(val, "#{key}")
          end
        EOE_KVC_WRAPPER
      end
    end

    # Define accessors that send change notifications for an array.
    # The array instance variable must respond to the following methods:
    #
    #  length
    #  [index]
    #  [index]=
    #  insert(index,obj)
    #  delete_at(index)
    #
    # Notifications are only sent for accesses through the Cocoa methods:
    #  countOfKey, objectInKeyAtIndex_, insertObject_inKeyAtIndex_,
    #  removeObjectFromKeyAtIndex_, replaceObjectInKeyAtIndex_withObject_
    #
    def kvc_array_accessor(*args)
      args.each do |key|
        keyname = key.to_s
        keyname[0..0] = keyname[0..0].upcase
        self.addRubyMethod_withType("countOf#{keyname}".to_sym, "i4@8:12")
        self.addRubyMethod_withType("objectIn#{keyname}AtIndex:".to_sym, "@4@8:12i16")
        self.addRubyMethod_withType("insertObject:in#{keyname}AtIndex:".to_sym, "@4@8:12@16i20")
        self.addRubyMethod_withType("removeObjectFrom#{keyname}AtIndex:".to_sym, "@4@8:12i16")
        self.addRubyMethod_withType("replaceObjectIn#{keyname}AtIndex:withObject:".to_sym, "@4@8:12i16@20")
        # get%s:range: - unimplemented. You can implement this method for performance improvements.
        self.class_eval <<-EOT,__FILE__,__LINE__+1
          def countOf#{keyname}()
            @#{key.to_s}.length
          end

          def objectIn#{keyname}AtIndex(index)
            @#{key.to_s}[index]
          end

          def insertObject_in#{keyname}AtIndex(obj, index)
            indexes = OSX::NSIndexSet.indexSetWithIndex(index)
	    if self.class.automaticallyNotifiesObserversForKey('#{key.to_s}')
	      willChange_valuesAtIndexes_forKey(OSX::NSKeyValueChangeInsertion, indexes, #{key.inspect})
	      @#{key.to_s}.insert(index, obj)
	      didChange_valuesAtIndexes_forKey(OSX::NSKeyValueChangeInsertion, indexes, #{key.inspect})
	    else
	      @#{key.to_s}.insert(index, obj)
	    end
            nil
          end

          def removeObjectFrom#{keyname}AtIndex(index)
            indexes = OSX::NSIndexSet.indexSetWithIndex(index)
	    if self.class.automaticallyNotifiesObserversForKey('#{key.to_s}')
	      willChange_valuesAtIndexes_forKey(OSX::NSKeyValueChangeRemoval, indexes, #{key.inspect})
	      @#{key.to_s}.delete_at(index)
	      didChange_valuesAtIndexes_forKey(OSX::NSKeyValueChangeRemoval, indexes, #{key.inspect})
	    else
	      @#{key.to_s}.delete_at(index)
	    end
            nil
          end

          def replaceObjectIn#{keyname}AtIndex_withObject(index, obj)
            indexes = OSX::NSIndexSet.indexSetWithIndex(index)
	    if self.class.automaticallyNotifiesObserversForKey('#{key.to_s}')
	      willChange_valuesAtIndexes_forKey(OSX::NSKeyValueChangeReplacement, indexes, #{key.inspect})
	      @#{key.to_s}[index] = obj
	      didChange_valuesAtIndexes_forKey(OSX::NSKeyValueChangeReplacement, indexes, #{key.inspect})
	    else
	      @#{key.to_s}[index] = obj
	    end
            nil
          end
        EOT
      end
    end

    # re-wrap at overriding setter method
    def _kvc_behavior_method_added(sym)
      return unless sym.to_s =~ /\A([^=]+)=\z/
      key = $1
      setter = kvc_internal_setter(key)
      wrapper = kvc_setter_wrapper(key)
      return unless method_defined?(setter) && method_defined?(wrapper)
      return if instance_method(wrapper) == instance_method(sym)
      alias_method setter, sym
      alias_method sym, wrapper
    end

  end       # module OSX::NSKVCBehaviorAttachment

  module OCObjWrapper

    include NSKeyValueCodingAttachment
  
  end

  module OCClsWrapper

    include OCObjWrapper
    include NSBehaviorAttachment
    include NSKVCBehaviorAttachment

    def singleton_method_added(sym)
      _ns_behavior_method_added(sym, true)
    end 
 
    def method_added(sym)
      _ns_behavior_method_added(sym, false)
      _kvc_behavior_method_added(sym)
    end

  end

end       # module OSX

# The following code defines a new subclass of Object (Ruby's).
# 
#    module OSX 
#      class NSCocoaClass end 
#    end
#
# This Object.inherited() replaces the subclass of Object class by 
# a Cocoa class from # OSX.ns_import.
#
class Object
  class <<self
    def _real_class_and_mod(klass)
      unless klass.ancestors.include?(OSX::Boxed)
        klassname = klass.name.to_s
        unless klassname.nil? || klassname.empty?
          if Object.included_modules.include?(OSX) and /::/.match(klassname).nil?
            [klassname, Object]
          elsif klassname[0..4] == 'OSX::' and (tokens = klassname.split(/::/)).size == 2 and klass.superclass != OSX::Boxed
            [tokens[1], OSX]
          end
        end
      end
    end

    alias _before_osx_inherited inherited
    def inherited(subklass)
      nsklassname, mod = _real_class_and_mod(subklass) 
      if nsklassname and (first_char = nsklassname[0]) >= ?A and first_char <= ?Z
        # remove Ruby's class
        mod.instance_eval { remove_const nsklassname.intern }
        begin
          klass = OSX.ns_import nsklassname.intern
          raise NameError if klass.nil?
          subklass = klass
        rescue NameError
          # redefine subclass (looks not a Cocoa class)
          mod.const_set(nsklassname, subklass)
        end
      end
      _before_osx_inherited(subklass)
    end

    def _register_method(sym, class_method)
      if self != Object
        nsklassname, mod = _real_class_and_mod(self)
        if nsklassname
          begin
            nsklass = OSX.const_get(nsklassname)
            raise NameError unless nsklass.ancestors.include?(OSX::NSObject)
            if class_method
              method = self.method(sym).unbind
              OSX.__rebind_umethod__(nsklass.class, method)
              nsklass.module_eval do 
                @__imported_arity = method.arity
                (class << self; self; end).instance_eval do 
                  define_method(sym, method)
                end
                @__imported_arity = nil
              end
            else
              method = self.instance_method(sym)
              OSX.__rebind_umethod__(nsklass, method)
              nsklass.module_eval do
                @__imported_arity = method.arity
                define_method(sym, method)
                @__imported_arity = nil
              end
            end
          rescue NameError
          end
        end
      end
    end

    alias _before_method_added method_added
    def method_added(sym)
      _register_method(sym, false)
      _before_method_added(sym)
    end

    alias _before_singleton_method_added singleton_method_added
    def singleton_method_added(sym)
      _register_method(sym, true)
      _before_singleton_method_added(sym)
    end

    def method_missing(symbol, *args)
      nsklassname, mod = _real_class_and_mod(self)
      if nsklassname
        begin
          nsklass = OSX.const_get(nsklassname)
          if nsklass.respond_to?(symbol)
            return nsklass.send(symbol, *args)
          end
        rescue NameError
        end
      end
      raise NoMethodError, "undefined method `#{symbol.to_s}' for #{self}"
    end
  end
end
