# Copyright (c) 2006-2008, The RubyCocoa Project.
# Copyright (c) 2001-2006, FUJIMOTO Hisakuni.
# All Rights Reserved.
#
# RubyCocoa is free software, covered under either the Ruby's license or the 
# LGPL. See the COPYRIGHT file for more information.

module OSX

  class << self
    attr_accessor :relaxed_syntax

    # Backward compatibility check; get C constants
    def method_missing(mname, *args)
      if args.length == 0
        begin
          ret = const_get(mname)
          warn "#{caller[0]}: syntax 'OSX.#{mname}' to get the constant is deprecated and its use is discouraged, please use 'OSX::#{mname}' instead."
          return ret
        rescue
        end
      end
      super
    end
  end

  module OCObjWrapper

    # A convenience method to dispatch a message to ObjC as symbol/value/...
    # For example, [myObj doSomething:arg1 withObject:arg2] would translate as:
    #   myObj.objc_send(:doSomething, arg1, :withObject, arg2)
    def objc_send(*args)
      raise ArgumentError, "wrong number of arguments (#{args.length} for at least 1)" if args.empty?
      mname = ""
      margs = []
      args.each_with_index do |val, index|
        if index % 2 == 0 then
          mname << val.to_s << ':'
        else
          margs << val
        end
      end
      mname.chomp!(':') if args.size == 1
      return self.ocm_send(mname.to_sel, nil, false, *margs)
    end

    def method_missing(mname, *args)
      m_name, m_args, as_predicate = analyze_missing(mname, args)
      begin
        result = self.ocm_send(m_name, mname, as_predicate, *m_args)
      rescue OCMessageSendException => e
        if self.private_methods.include?(mname.to_s)
          raise NoMethodError, "private method `#{mname}' called for ##{self}"
        else
          raise e
        end 
      end
    end

    def ocnil?
      self.__ocid__ == 0
    end

    private

    def analyze_missing(mname, args)
      m_name = mname.to_s
      m_args = args

      # remove `oc_' prefix
      m_name.sub!(/^oc_/, '')

      # remove `?' suffix (to keep compatibility)
      # explicit predicate if `?' suffix with OSX.relaxed_syntax
      as_predicate = false
      if m_name[-1] == ??
        m_name.chop!
        as_predicate = OSX.relaxed_syntax
        # convert foo? to isFoo
        orig_sel = m_args.size > 0 ? m_name.sub(/[^_:]$/, '\0_')  : m_name
        unless ocm_responds?(orig_sel)
          m_name = 'is' + m_name[0].chr.upcase + m_name[1..-1]
        end
      end

      # convert foo= to setFoo
      if m_name[-1] == ?= and m_name.index(?_, 1).nil?
        m_name.chop!
        m_name = 'set' + m_name[0].chr.upcase + m_name[1..-1]
      end

      # check call style
      #   as Objective-C: [self aaa: a0 Bbb: a1 Ccc: a2]
      #   as Ruby:   self.aaa_Bbb_Ccc_ (a0, a1, a2)
      # only if OSX.relaxed_syntax == true, check missing final underscore
      #   as Ruby:   self.aaa_Bbb_Ccc (a0, a1, a2)
      # other syntaxes are now deprecated
      #   as Ruby:   self.aaa (a0, :Bbb, a1, :Ccc, a2)
      #   as Ruby:   self.aaa (a0, :Bbb => a1, :Ccc => a2)
      if OSX.relaxed_syntax
        if (m_args.size == 2) && (not m_name.include?('_')) && m_args[1].is_a?(Hash) && (m_args[1].size >= 1) then
          # Parse the inline Hash case.
          mname = m_name.dup
          args = []
          args << m_args[0]
          if m_args[1].size == 1
            m_args[1].each do |key, val|
              mname << "_#{key}"
              args << val
            end
          else
            # FIXME: do some caching here
            self.objc_methods.each do |sel|
              selname, *selargs = sel.split(/:/)
              if selname == m_name and selargs.all? { |selarg| m_args[1].has_key?(selarg.to_sym) } then
                selargs.each do |selarg|
                  mname << "_#{selarg}"
                  args << m_args[1][selarg.to_sym]
                end
                break
              end
            end
          end
          m_name = "#{mname}_"
          m_args = args
          warn "#{caller[1]}: inline Hash dispatch syntax is deprecated and its use is discouraged, please use '#{m_name}(...)' or 'objc_send(...)' instead."
        elsif (m_args.size >= 3) && ((m_args.size % 2) == 1) && (not m_name.include?('_')) && (m_args.values_at(*(1..m_args.size - 1).to_a.select { |i| i % 2 != 0 }).all? { |x| x.is_a?(Symbol) }) then
          # Parse the symbol-value-symbol-value-... case.
          mname = m_name.dup
          args = []
          m_args.each_with_index do |val, index|
            if (index % 2) == 0 then
              args << val
            else
              mname << "_#{val.to_s}"
            end
          end
          m_name = "#{mname}_"
          warn "#{caller[1]}: symbol-value-... dispatch syntax is deprecated and its use is discouraged, please use '#{m_name}(...)' or 'objc_send(...)' instead."
          m_args = args
        else
          m_name.sub!(/[^_:]$/, '\0_') if m_args.size > 0
        end
      end
      return [ m_name, m_args, as_predicate ]
    end

  end

end				# module OSX
