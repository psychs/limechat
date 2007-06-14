# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the same terms as Ruby.

require 'resolv'

class Resolver
  def resolv(host)
    Resolv.getaddress(host)
  end
end
