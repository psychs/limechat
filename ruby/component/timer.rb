# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the same terms as Ruby.

class Timer < OSX::NSObject
  include OSX
  attr_accessor :delegate
  
  def active?
    @timer != nil
  end
  
  def start(interval)
    stop if active?
    @timer = NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(interval, self, 'onTimer:', nil, true)
    NSRunLoop.currentRunLoop.addTimer_forMode(@timer, NSEventTrackingRunLoopMode)
  end
  
  def stop
    return unless active?
    @timer.invalidate
    @timer = nil
  end
  
  def onTimer(sender)
    if active? && @delegate
      @delegate.timer_onTimer(self)
    end
  end
end
