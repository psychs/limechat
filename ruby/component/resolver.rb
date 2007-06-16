# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the same terms as Ruby.

require 'resolv'

class Resolver
  def self.resolve(sender, host)
    Thread.new do
      addr = Resolv.getaddresses(host)
      sender.performSelectorOnMainThread_withObject_waitUntilDone('Resolver_onResolve:', addr, false)
    end
    nil
  end
end
