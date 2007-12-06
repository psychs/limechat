# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

module UrlOpener
  def self.openUrl(str)
    urls = [NSURL.URLWithString(str)]
    NSWorkspace.sharedWorkspace.openURLs_withAppBundleIdentifier_options_additionalEventParamDescriptor_launchIdentifiers(urls, nil, NSWorkspaceLaunchAsync, nil, nil)
  end
end
