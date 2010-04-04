# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'preferences'

class UrlOpener < NSObject
  def self.openUrl(str)
    if preferences.general.open_browser_in_background
      urls = [OSX::NSURL.URLWithString(str)]
      OSX::NSWorkspace.sharedWorkspace.openURLs_withAppBundleIdentifier_options_additionalEventParamDescriptor_launchIdentifiers(urls, nil, NSWorkspaceLaunchWithoutActivation, nil, nil)
    else
      url = OSX::NSURL.URLWithString(str)
      OSX::NSWorkspace.sharedWorkspace.openURL(url)
    end
  end
end
