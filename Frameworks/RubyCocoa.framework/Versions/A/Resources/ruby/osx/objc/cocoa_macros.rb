# Copyright (c) 2006-2008, The RubyCocoa Project.
# Copyright (c) 2001-2006, FUJIMOTO Hisakuni.
# All Rights Reserved.
#
# RubyCocoa is free software, covered under either the Ruby's license or the 
# LGPL. See the COPYRIGHT file for more information.

require 'nkf'

module OSX

  # from NSBundle
  def NSLocalizedString (key, comment = nil)
    OSX::NSBundle.mainBundle.
      localizedStringForKey_value_table(key, "", nil)
  end
  def NSLocalizedStringFromTable (key, tbl, comment = nil)
    OSX::NSBundle.mainBundle.
      localizedStringForKey_value_table(key, "", tbl)
  end
  def NSLocalizedStringFromTableInBundle (key, tbl, bundle, comment = nil)
    bundle.localizedStringForKey_value_table(key, "", tbl)
  end
  module_function :NSLocalizedStringFromTableInBundle
  module_function :NSLocalizedStringFromTable
  module_function :NSLocalizedString

  # for NSData
  class NSData

    def NSData.dataWithRubyString (str)
      NSData.dataWithBytes_length( str )
    end

  end

  # for NSMutableData
  class NSMutableData

    def NSMutableData.dataWithRubyString (str)
      NSMutableData.dataWithBytes_length( str )
    end

  end

  # for NSString
  class NSString

    def NSString.guess_nsencoding(rbstr)
      case NSString.guess_encoding(rbstr)
      when NKF::JIS then NSISO2022JPStringEncoding
      when NKF::EUC then NSJapaneseEUCStringEncoding
      when NKF::SJIS then NSShiftJISStringEncoding
      else 
        if defined? NSProprietaryStringEncoding
          NSProprietaryStringEncoding
        else
          NSUTF8StringEncoding
        end
      end
    end

    def NSString.guess_encoding(rbstr)
      NKF.guess(rbstr)
    end

    # NKF.guess fails on ruby-1.8.2
    if NKF.respond_to?('guess1') && NKF::NKF_VERSION == "2.0.4"
      def NSString.guess_encoding(rbstr)
        NKF.guess1(rbstr)
      end
    end

    def NSString.stringWithRubyString (str)
      data = NSData.dataWithRubyString( str )
      enc = guess_nsencoding( str )
      NSString.alloc.initWithData_encoding( data, enc )
    end

  end

  # for NSMutableString
  class NSMutableString
    def NSMutableString.stringWithRubyString (str)
      data = NSData.dataWithRubyString( str )
      enc = NSString.guess_nsencoding( str )
      NSMutableString.alloc.initWithData_encoding( data, enc )
    end
  end

  # This moved there as osx/coredata is now deprecated.
  module CoreData
    # define wrappers from NSManagedObjectModel
    def define_wrapper(model)
      unless model.isKindOfClass? OSX::NSManagedObjectModel
        raise RuntimeError, "invalid class: #{model.class}"
      end

      model.entities.each do |ent|
        CoreData.define_wrapper_for_entity(ent)
      end
    end
    module_function :define_wrapper

    def define_wrapper_for_entity(entity)
      klassname = entity.managedObjectClassName.to_s
      return if klassname == 'NSManagedObject'
      unless Object.const_defined?(klassname)
	warn "define_wrapper_for_entity: class \"#{klassname}\" is not defined."
        return
      end

      attrs = entity.attributesByName.allKeys.collect {|key| key.to_s}
      rels = entity.relationshipsByName.allKeys.collect {|key| key.to_s}
      klass = Object.const_get(klassname)
      klass.instance_eval <<-EOE_AUTOWRAP,__FILE__,__LINE__+1
	kvc_wrapper attrs
	kvc_wrapper_reader rels
      EOE_AUTOWRAP
    end
    module_function :define_wrapper_for_entity
  end

end
