# Copyright (c) 2006-2008, The RubyCocoa Project.
# Copyright (c) 2001-2006, FUJIMOTO Hisakuni.
# All Rights Reserved.
#
# RubyCocoa is free software, covered under either the Ruby's license or the 
# LGPL. See the COPYRIGHT file for more information.

module OSX

  module BundleSupport

    def init_for_bundle(option = nil)
      ret = nil
      bdl, prm = _current_bundle
      logger = Logger.new(bdl)
      logger.info("init_for_bundle ...") if OSX._debug? || (option && option[:verbose])
      yield(bdl, prm, logger)
      logger.info("init_for_bundle done.") if OSX._debug? || (option && option[:verbose])
      nil
    rescue Exception => err
      logger.error(err)
      logger.info("init_for_bundle failed.")
      raise
    end
    module_function :init_for_bundle

    private
    class Logger
      def initialize(bdl)
        @bundle_name  = bdl.to_s.sub(/^.*<(.*)>.*$/,'\1').split('/').last
        @process_name = OSX::NSProcessInfo.processInfo.processName
      end

      def info(fmt, *args)
        OSX.NSLog("#{@bundle_name} (#{@process_name}): #{fmt % args}")
      end
      
      def error(err)
        info("%s: %s", err.class, err)
      end

      def backtrace(err)
        err.backtrace.each { |s| info("    %s", s) }
      end
    end
  end

  def init_for_bundle(args = nil)
    BundleSupport.init_for_bundle(args) { |*x| yield(*x) }
  end
  module_function :init_for_bundle

end
