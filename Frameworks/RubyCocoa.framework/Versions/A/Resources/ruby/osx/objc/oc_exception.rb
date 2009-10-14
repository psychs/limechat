# Copyright (c) 2006-2008, The RubyCocoa Project.
# Copyright (c) 2001-2006, FUJIMOTO Hisakuni.
# All Rights Reserved.
#
# RubyCocoa is free software, covered under either the Ruby's license or the 
# LGPL. See the COPYRIGHT file for more information.

module OSX

  def self._debug?
    ($DEBUG || $RUBYCOCOA_DEBUG)
  end

  class OCException < RuntimeError

    attr_reader :name, :reason, :userInfo, :nsexception

    def initialize(ocexcp, msg = nil)
      @nsexception = ocexcp
      @name = @nsexception.objc_send(:name).to_s
      @reason = @nsexception.objc_send(:reason).to_s
      @userInfo = @nsexception.objc_send(:userInfo)
      msg = "#{@name} - #{@reason}" if msg.nil?
      super(msg)
    end

  end

  class OCDataConvException < RuntimeError
  end

  class OCMessageSendException < RuntimeError
  end

end
