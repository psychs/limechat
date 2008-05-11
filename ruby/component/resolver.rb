# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'resolv'

class Resolver
  def self.resolve(sender, host)
    Thread.new do
      addr = Resolv.getaddresses(host)
      sender.performSelectorOnMainThread_withObject_waitUntilDone('ResolverOnResolve:', addr, false)
    end
    nil
  end
end
