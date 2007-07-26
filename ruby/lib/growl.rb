# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class Growl < OSX::NSObject
  include OSX
  
  GROWL_IS_READY = "Lend Me Some Sugar; I Am Your Neighbor!"
  GROWL_NOTIFICATION_CLICKED = "GrowlClicked!"
  GROWL_NOTIFICATION_TIMED_OUT = "GrowlTimedOut!"
  GROWL_KEY_CLICKED_CONTEXT = "ClickedContext"

  def setup(appname, notes, defnotes=nil, appicon=nil)
    @appname = appname
    @notes = notes
    @defnotes = defnotes
    @appicon = appicon
    @appicon = NSWorkspace.sharedWorkspace.iconForFileType('txt') unless @appicon
    @defnotes = @notes unless @defnotes
    register
  end
  
  def notify(notetype, title, desc, click_context=nil, sticky=false, priority=0, icon=nil, app_icon=nil)
    icon = @appicon unless icon
    
    dic = {
      :ApplicationName => @appname,
      :ApplicationPID => NSProcessInfo.processInfo.processIdentifier,
      :NotificationName => notetype,
      :NotificationTitle => title,
      :NotificationDescription => desc,
      :NotificationIcon => icon.TIFFRepresentation,
      :NotificationPriority => priority
    }
    dic[:NotificationAppIcon] = app_icon.TIFFRepresentation if app_icon
    dic[:NotificationSticky] = 1 if sticky
    dic[:NotificationClickContext] = click_context if click_context
    
    c = NSDistributedNotificationCenter.defaultCenter
    c.postNotificationName_object_userInfo_deliverImmediately(:GrowlNotification, nil, dic, true)
  end
  
  def onReady(note)
    register
  end
  
  def onClicked(note)
    context = note.userInfo[GROWL_KEY_CLICKED_CONTEXT].to_s
    puts 'clicked'
  end
  
  def onTimeout(note)
    context = note.userInfo[GROWL_KEY_CLICKED_CONTEXT].to_s
    puts 'timeout'
  end
  
  private
  
  def register
    pid = NSProcessInfo.processInfo.processIdentifier.to_i
    
    c = NSDistributedNotificationCenter.defaultCenter
    c.addObserver_selector_name_object(self, 'onReady:', GROWL_IS_READY, nil)
    c.addObserver_selector_name_object(self, 'onClicked:', "#{@appname}-#{pid}-#{GROWL_NOTIFICATION_CLICKED}", nil)
    c.addObserver_selector_name_object(self, 'onTimeout:', "#{@appname}-#{pid}-#{GROWL_NOTIFICATION_TIMED_OUT}", nil)

    dic = {
      :ApplicationName => @appname,
      :AllNotifications => @notes,
      :DefaultNotifications => @defnotes,
      :ApplicationIcon => @appicon.TIFFRepresentation
    }
    c.postNotificationName_object_userInfo_deliverImmediately(:GrowlApplicationRegistrationNotification, nil, dic, true)
  end
end
