# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the same terms as Ruby.

module UrlOpener
  include OSX
  
  def self.openUrl(str)
    url = NSArray.arrayWithObject(NSURL.URLWithString(str))
    NSWorkspace.sharedWorkspace.openURLs_withAppBundleIdentifier_options_additionalEventParamDescriptor_launchIdentifiers(url, nil, NSWorkspaceLaunchAsync, nil, nil)
  end
end
