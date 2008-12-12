# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

module UrlOpener
  
  def openUrl(str)
    urls = [OSX::NSURL.URLWithString(str)]
    OSX::NSWorkspace.sharedWorkspace.openURLs_withAppBundleIdentifier_options_additionalEventParamDescriptor_launchIdentifiers(urls, nil, NSWorkspaceLaunchWithoutActivation, nil, nil)
  end
  
  extend self
end
