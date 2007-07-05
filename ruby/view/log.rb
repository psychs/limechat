# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'cgi'
require 'uri'
require 'logrenderer'

class LogLine
  attr_accessor :time, :place, :nick, :body
  attr_accessor :line_type, :member_type
  attr_accessor :nick_info, :click_info
  
  def initialize(time, place, nick, body, line_type=:system, member_type=:normal, nick_info=nil, click_info=nil)
    @time = time
    @place = place
    @nick = nick
    @body = body
    @line_type = line_type
    @member_type = member_type
    @nick_info = nick_info
    @click_info = click_info
  end
end


class LogController < OSX::NSObject
  include OSX
  attr_accessor :world, :menu, :max_lines, :keyword
  attr_reader :view, :console, :bottom
  
  BOTTOM_EPSILON = 20
  
  def initialize
    @bottom = true
    @lines = []
    @line_number = 0
    @loaded = false
    @max_lines = 1000
  end
  
  def setup(console=false)
    @console = console
    @policy = LogPolicy.alloc.init
    @policy.menu = @menu
    @view = LogView.alloc.initWithFrame(NSZeroRect)
    @view.setFrameLoadDelegate(self)
    @view.setUIDelegate(@policy)
    @view.setPolicyDelegate(@policy)
    #@view.setResourceLoadDelegate(self)
    @view.key_delegate = self
    @view.resize_delegate = self
    @view.setAutoresizingMask(NSViewWidthSizable | NSViewHeightSizable)
    @view.mainFrame.loadHTMLString_baseURL(initial_doc, nil)
  end
  
  def moveToTop
    body = @view.mainFrame.DOMDocument.body
    body.setValue_forKey(0, 'scrollTop')
  end
  
  def moveToBottom
    body = @view.mainFrame.DOMDocument.body
    scrollheight = body.valueForKey('scrollHeight').to_i
    body.setValue_forKey(scrollheight, 'scrollTop')
  end
  
  def viewing_bottom?
    return true unless @loaded
    body = @view.mainFrame.DOMDocument.body
    #viewheight = @view.mainFrame.frameView.documentView.visibleRect.size.height.to_i
    viewheight = @view.frame.size.height.to_i
    scrollheight = body.valueForKey('scrollHeight').to_i
    scrolltop = body.valueForKey('scrollTop').to_i
    (viewheight == 0) || (scrolltop + viewheight >= scrollheight - BOTTOM_EPSILON)
  end
  
  def save_position
    @bottom = viewing_bottom?
  end
  
  def restore_position
    return unless @loaded
    moveToBottom if @bottom
  end
  
  def print(line, use_keyword)
    body, key = build_body(line, use_keyword)
    
    unless @loaded
      @lines << [line, use_keyword]
      return key
    end
    
    s = ''
    s += %Q[<span class="time">#{h(line.time)}</span>] if line.time
    s += %Q[<span class="place">#{h(line.place)}</span>] if line.place
    s += %Q[<span class="nick_#{line.member_type}">#{h(line.nick)}</span>] if line.nick
    s += %Q[<span class="#{line.line_type}">#{body}</span>]
    attrs = {}
    attrs['class'] = 'line'
    attrs['type'] = line.line_type.to_s
    if @console
      if line.click_info
        attrs['clickinfo'] = line.click_info 
        attrs['ondblclick'] = %Q[on_dblclick()]
      end
    else
      attrs['nick'] = line.nick_info if line.nick_info
    end
    write(s, attrs)
    key
  end
  
  # delegate
  
  def webView_windowScriptObjectAvailable(sender, js)
    @js = js
    sink = LogScriptEventSink.alloc.init
    sink.owner = self
    @js.setValue_forKey(sink, 'app')
  end
  
  def webView_didFinishLoadForFrame(sender, frame)
    @loaded = true
    @lines.each {|i| print(*i) }
    @lines.clear
    
    body = @view.mainFrame.DOMDocument.body
    e = body.firstChild
    while e
      n = e.nextSibling
      body.removeChild_(e) if e.class.name.to_s != 'OSX::DOMHTMLDivElement'
      e = n
    end
    
    if @console
      script = <<-EOM
        function on_dblclick() {
          var t = event.target
          while (t && !(t.tagName == 'DIV' && t.className == 'line')) {
            t = t.parentNode
          }
          if (t) {
            app.onDblClick(t.getAttribute('clickinfo'))
          }
          event.stopPropagation()
        }
        function on_mousedown() {
          if (app.shouldStopDoubleClick(event)){
            event.preventDefault()
          }
          event.stopPropagation()
        }
        
        document.addEventListener('mousedown', on_mousedown, false)
      EOM
      @js.evaluateWebScript(script)
    end
  end
  
  def logView_keyDown(e)
    @world.log_keyDown(e)
  end
  
  def logView_willResize(rect)
    save_position
  end
  
  def logView_didResize(rect)
    restore_position
  end
  
  def logView_onDoubleClick(s)
    @world.log_doubleClick(s)
  end
  
  
  private
  
  def build_body(line, use_keyword)
    if use_keyword
      case line.line_type
      when :privmsg,:action
        use_keyword = false if line.member_type == :myself
      else
        use_keyword = false
      end
    end
    
    if use_keyword
      like = @keyword.words
      dislike = @keyword.dislike_words
    else
      like = dislike = nil
    end
    
    LogRenderer.render_body(line.body, like, dislike)
  end
  
  def h(s)
    s ? CGI.escapeHTML(s.to_s) : ''
  end
  
  def write(html, attrs)
    save_position
    
    @line_number += 1
    doc = @view.mainFrame.DOMDocument
    body = doc.body
    
    div = doc.createElement('div')
    div.setInnerHTML(html)
    attrs.each {|k,v| div.setAttribute__(k, v) } if attrs
    div.setAttribute__('id', "line#{@line_number}")
    body.appendChild(div)
    
    body.removeChild_(body.firstChild) if @max_lines > 0 && @line_number > @max_lines
    
    restore_position
  end
  
  def initial_doc
    <<-EOM
      <html>
      <style>
        body {
          font-family: 'Osaka-Mono';
          font-size: 10pt;
          word-wrap: break-word;
          margin: 3px 4px 10px 4px;
          padding: 0;
        }
        img { border: 1px solid #aaa; vertical-align: top; }
        object { vertical-align: top; }
        strong { color: #f0f; font-weight: bold; }
        .line { margin: 2px 0; }
        .time { color: #048; }
        .place { color: #008; }
        .nick_normal { color: #008; }
        .nick_myself { color: #66a; }
        .system { color: #080; }
        .error { color: #f00; font-weight: bold; }
        .reply { color: #088; }
        .error_reply { color: #f00; }
        .dcc_send_send { color: #088; }
        .dcc_send_receive { color: #00c; }
        .privmsg { color: #000; }
        .notice { color: #888; }
        .action { color: #080; }
        .join { color: #080; }
        .part { color: #080; }
        .kick { color: #080; }
        .quit { color: #080; }
        .kill { color: #080; }
        .nick { color: #080; }
        .mode { color: #080; }
        .topic { color: #080; }
        .invite { color: #080; }
        .wallops { color: #080; }
        .debug_send { color: #880; }
        .debug_receive { color: #444; }
      </style>
      <body></body>
      </html>
    EOM
  end
end


class LogScriptEventSink < OSX::NSObject
  include OSX
  attr_accessor :owner
  
  EXPORTED_METHODS = %w|onDblClick: shouldStopDoubleClick: print:|

  objc_class_method 'isSelectorExcludedFromWebScript:', 'c@::'
  def self.isSelectorExcludedFromWebScript(sel)
    case sel
    when *EXPORTED_METHODS
      false
    else
      true
    end
  end

  objc_class_method 'webScriptNameForSelector:', '@@::'
  def self.webScriptNameForSelector(sel)
    case sel
    when *EXPORTED_METHODS
      sel[-1,1] = ''
      sel
    else
      nil
    end
  end

  objc_class_method :isKeyExcludedFromWebScript, 'c@:*'
  def self.isKeyExcludedFromWebScript(name)
    true
  end
  
  objc_class_method :webScriptNameForKey, '@@:*'
  def self.webScriptNameForKey(name)
    nil
  end
  
  DELTA = 3
  
  def initialize
    @last = 0.0
    @x = -100
    @y = -100
  end
  
  objc_method :onDblClick, 'v@:@'
  def onDblClick(e)
    @owner.logView_onDoubleClick(e.to_s)
  end
  
  objc_method :shouldStopDoubleClick, 'c@:@'
  def shouldStopDoubleClick(e)
    d = DELTA
    cx = e.valueForKey('clientX').intValue
    cy = e.valueForKey('clientY').intValue
    res = false
    
    now = NSDate.timeIntervalSinceReferenceDate.to_f
    if @x-d <= cx && cx <= @x+d && @y-d <= cy && cy <= @y+d
      res = true if now < @last + (OldEventManager.getDoubleClickTime.to_f / 60.0)
    end
    @last = now
    @x = cx
    @y = cy
    res
  end
  
  objc_method :print, 'v@:@'
  def print(s)
    NSLog("%@", s)
  end
end


class LogPolicy < OSX::NSObject
  include OSX
  attr_accessor :menu

  objc_method :webView_dragDestinationActionMaskForDraggingInfo, 'i@:@@'
  def webView_dragDestinationActionMaskForDraggingInfo(sender, info)
    0 #WebDragDestinationActionNone
  end
  
  def webView_contextMenuItemsForElement_defaultMenuItems(sender, element, defaultMenu)
    if @menu
      @menu.itemArray.to_a.map {|i| i.copy }
    else
      []
    end
  end

  def webView_decidePolicyForNavigationAction_request_frame_decisionListener(sender, action, request, frame, listener)
    case action.objectForKey(:WebActionNavigationTypeKey).intValue.to_i
    when 0  #WebNavigationTypeLinkClicked
      listener.ignore
      UrlOpener::openUrl(action.objectForKey(:WebActionOriginalURLKey).absoluteString)
    when 5  #WebNavigationTypeOther
      listener.use
    else
      listener.ignore
    end
  end
end
