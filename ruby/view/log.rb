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


class LogController < NSObject
  attr_accessor :world
  attr_writer :unit, :menu, :url_menu, :addr_menu, :member_menu, :keyword, :theme, :override_font
  attr_reader :view
  
  def initialize
    @bottom = true
    @lines = []
    @line_number = 0
    @count = 0
    @loaded = false
    @max_lines = 300
  end
  
  def setup(console, initial_bgcolor)
    @loaded = false
    @console = console
    @policy = LogPolicy.alloc.init
    @policy.owner = self
    @policy.menu = @menu
    @policy.url_menu = @url_menu
    @policy.addr_menu = @addr_menu
    @policy.member_menu = @member_menu
    @sink = LogScriptEventSink.alloc.init
    @sink.owner = self
    @sink.policy = @policy
    @view.release if @view
    @view = LogView.alloc.initWithFrame(NSZeroRect)
    @view.setBackgroundColor(initial_bgcolor) if @view.respondsToSelector('setBackgroundColor:')
    @view.setFrameLoadDelegate(self)
    @view.setUIDelegate(@policy)
    @view.setPolicyDelegate(@policy)
    #@view.setResourceLoadDelegate(self)
    @view.key_delegate = self
    @view.resize_delegate = self
    @view.setAutoresizingMask(NSViewWidthSizable | NSViewHeightSizable)
    @view.mainFrame.loadHTMLString_baseURL(initial_document, @theme.baseurl)
  end
  
  def max_lines=(n)
    return if @max_lines == n
    @max_lines = n
    return unless @loaded
    
    if @max_lines > 0 && @count > @max_lines
      save_position
      remove_first_line(@count - @max_lines)
      restore_position
    end
  end
  
  def moveToTop
    return unless @loaded
    doc = @view.mainFrame.DOMDocument
    return unless doc
    body = doc.body
    body.setValue_forKey(0, 'scrollTop')
  end
  
  def moveToBottom
    return unless @loaded
    doc = @view.mainFrame.DOMDocument
    return unless doc
    body = doc.body
    scrollheight = body.valueForKey('scrollHeight').to_i
    body.setValue_forKey(scrollheight, 'scrollTop')
  end
  
  BOTTOM_EPSILON = 20
  
  def viewing_bottom?
    return true unless @loaded
    doc = @view.mainFrame.DOMDocument
    return true unless doc
    body = doc.body
    viewheight = @view.frame.height.to_i rescue 0
    scrollheight = body.valueForKey('scrollHeight').to_i
    scrolltop = body.valueForKey('scrollTop').to_i
    (viewheight == 0) || (scrolltop + viewheight >= scrollheight - BOTTOM_EPSILON)
  end
  
  def save_position
    @bottom = viewing_bottom?
  end
  
  def restore_position
    moveToBottom if @bottom
  end
  
  def content_string
    return nil unless @loaded
    doc = @view.mainFrame.DOMDocument
    return nil unless doc
    doc.body.parentNode.outerHTML.to_s
  rescue
    nil
  end
  
  def print(line, use_keyword=true)
    body, key = build_body(line, use_keyword)
    
    unless @loaded
      @lines << [line, use_keyword]
      return key
    end
    
    s = ''
    s << %|<span class="time">#{h(line.time)}</span>| if line.time
    s << %|<span class="place">#{h(line.place)}</span>| if line.place
    if line.nick
      s << %|<span class="sender nick_#{line.member_type}" type="#{line.member_type}"|
      s << %| oncontextmenu="on_nick_contextmenu()"| unless @console
      s << %|>#{h(line.nick)}</span>|
    end
    s << %[<span class="message #{line.line_type}" type="#{line.line_type}">#{body}</span>]
    
    attrs = {}
    alternate = @line_number % 2 == 0 ? 'even' : 'odd'
    attrs['alternate'] = alternate
    attrs['class'] = "line #{alternate}_line"
    attrs['type'] = line.line_type.to_s
    if @console
      if line.click_info
        attrs['clickinfo'] = line.click_info 
        attrs['ondblclick'] = %|on_dblclick()|
      end
    else
      attrs['nick'] = line.nick_info if line.nick_info
    end
    write_line(s, attrs)
    key
  end
  
  def mark
    return unless @loaded
    save_position
    unmark
    doc = @view.mainFrame.DOMDocument
    return unless doc
    e = doc.createElement('hr')
    e.setAttribute__('id', 'mark')
    doc.body.appendChild(e)
    restore_position
  end
  
  def unmark
    return unless @loaded
    doc = @view.mainFrame.DOMDocument
    return unless doc
    e = doc.getElementById('mark')
    doc.body.removeChild(e) if e
  end
  
  def use_small_scroller(v)
    subviews = @view.mainFrame.frameView.subviews
    scrollView = subviews.find {|i| i.is_a?(NSScrollView) }
    if scrollView
      scrollView.verticalScroller.setControlSize(v ? NSSmallControlSize : NSRegularControlSize)
      scrollView.setAutohidesScrollers(true)
    end
  end
  
  def reload_theme
    return unless @loaded
    doc = @view.mainFrame.DOMDocument
    return unless doc
    body = doc.body
    @html = body.innerHTML
    @scroll_bottom = viewing_bottom?
    @scroll_top = body.valueForKey('scrollTop').to_i
    #setup(@console, style)
    @view.mainFrame.loadHTMLString_baseURL(initial_document, @theme.baseurl)
  end
  
  def change_text_size(op)
    save_position
    if op == :bigger
      view.makeTextLarger(nil)
    else
      view.makeTextSmaller(nil)
    end
    restore_position
  end
  
  
  # delegate

  objc_method :webView_windowScriptObjectAvailable, 'v@:@@'
  def webView_windowScriptObjectAvailable(sender, js)
    @js = js
    @js.setValue_forKey(@sink, 'app')
  end
  
  objc_method :webView_didFinishLoadForFrame, 'v@:@@'
  def webView_didFinishLoadForFrame(sender, frame)
    @loaded = true
    if @html
      body = @view.mainFrame.DOMDocument.body
      body.innerHTML = @html
      if @scroll_bottom
        moveToBottom
      elsif @scroll_top
        body.setValue_forKey(@scroll_top, 'scrollTop')
      end
      @html = nil
      @scroll_bottom = nil
      @scroll_top = nil
    else
      moveToBottom
      @bottom = true
    end

    @lines.each {|i| print(*i) }
    @lines.clear

    body = @view.mainFrame.DOMDocument.body
    e = body.firstChild
    while e
      n = e.nextSibling	 
      body.removeChild(e) unless DOMHTMLDivElement === e || DOMHTMLHRElement === e
      e = n
    end
    
    if @console
      script = <<-EOM
        function on_dblclick() {
          var t = event.target
          while (t && !(t.tagName == 'DIV' && (t.className == 'line even_line' || t.className == 'line odd_line'))) {
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
        function on_url_contextmenu() {
          var t = event.target
          app.setUrl(t.innerHTML)
        }
        function on_address_contextmenu() {
          var t = event.target
          app.setAddr(t.innerHTML)
        }
        
        document.addEventListener('mousedown', on_mousedown, false)
      EOM
      @js.evaluateWebScript(script)
    else
      script = <<-EOM
        function on_url_contextmenu() {
          var t = event.target
          app.setUrl(t.innerHTML)
        }
        function on_address_contextmenu() {
          var t = event.target
          app.setAddr(t.innerHTML)
        }
        function on_nick_contextmenu() {
          var t = event.target
          app.setNick(t.parentNode.getAttribute('nick'))
        }
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
      dislike = @keyword.dislike_words
      like = @keyword.words
      if @unit && @keyword.current_nick && !@unit.mynick.empty?
        like += [@unit.mynick]
      end
    else
      like = dislike = nil
    end
    
    LogRenderer.render_body(line.body, like, dislike, @keyword.whole_line)
  end
  
  def h(s)
    #s ? CGI.escapeHTML(s.to_s) : ''
    s ? LogRenderer.escape_str(s) : ''
  end
  
  def remove_first_line(n=1)
    return unless @loaded
    return if n <= 0
    return if @count <= 0
    doc = @view.mainFrame.DOMDocument
    return unless doc
    body = doc.body
    n.times do
      node = body.firstChild
      if DOMHTMLElement === node && node.tagName.to_s.downcase == 'hr'
        # the first node is the mark
        next_sibling = node.nextSibling
        body.removeChild(node)
        node = next_sibling
      end
      body.removeChild(node)
    end
    @count -= n
  end
  
  def write_line(html, attrs)
    save_position
    @line_number += 1
    @count += 1
    
    doc = @view.mainFrame.DOMDocument
    return unless doc
    body = doc.body
    div = doc.createElement('div')
    div.setInnerHTML(html)
    attrs.each {|k,v| div.setAttribute__(k, v) } if attrs
    div.setAttribute__('id', "line#{@line_number}")
    body.appendChild(div)
    
    remove_first_line if @max_lines > 0 && @count > @max_lines
    restore_position
  end
  
  def initial_document
    body_class = @console ? 'console' : 'normal'
    style = @theme.content || ''
    if @override_font
      name = @override_font[0]
      size = @override_font[1] * (72.0 / 96.0)
      override_style = <<-EOM
        html {
          font-family: '#{name}';
          font-size: #{size}pt;
        }
      EOM
    else
      override_style = ''
    end
    <<-EOM
      <html>
      <head>
      <style>#{DEFAULT_CSS}</style>
      <style><!--#{style}--></style>
      <style>#{override_style}</style>
      </head>
      <body class="#{body_class}"></body>
      </html>
    EOM
  end
  
  if LanguageSupport.primary_language == 'ja'
    DEFAULT_FONT = 'Osaka-Mono'
    DEFAULT_FONT_SIZE = 10
  else
    DEFAULT_FONT = 'Courier'
    DEFAULT_FONT_SIZE = 9
  end
  
  DEFAULT_CSS = <<-EOM
    html {
      font-family: '#{DEFAULT_FONT}';
      font-size: #{DEFAULT_FONT_SIZE}pt;
      background-color: white;
      color: black;
      word-wrap: break-word;
      margin: 0;
      padding: 3px 4px 10px 4px;
    }
    body { margin: 0; padding: 0; }
    body.console {}
    body.normal {}
    img { border: 1px solid #aaa; vertical-align: top; }
    object { vertical-align: top; }
    hr { margin: 0.5em 2em; }
    .url { word-break: break-all; }
    .address { text-decoration: underline; word-break: break-all; }
    .highlight { color: #f0f; font-weight: bold; }
    .line { margin: 0 -4px; padding: 0 4px 1px 4px; }
    .even_line {}
    .odd_line {}
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
    .privmsg {}
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
    .debug_send { color: #aaa; }
    .debug_receive { color: #444; }
  EOM
end


class LogScriptEventSink < NSObject
  attr_accessor :owner, :policy
  
  EXPORTED_METHODS = %w|onDblClick: shouldStopDoubleClick: setUrl: setAddr: setNick: print:|

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
      sel[-1,1] = '' if sel[-1] == ?:
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
  
  def initialize
    @last = 0.0
    @x = -100
    @y = -100
  end
  
  objc_method :onDblClick, 'v@:@'
  def onDblClick(e)
    @owner.logView_onDoubleClick(e.to_s)
  end
  
  DELTA = 3
  
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
  
  objc_method :setUrl, 'v@:@'
  def setUrl(s)
    @policy.url = uh(s)
  end
  
  objc_method :setAddr, 'v@:@'
  def setAddr(s)
    @policy.addr = uh(s)
  end
  
  objc_method :setNick, 'v@:@'
  def setNick(s)
    @policy.nick = uh(s)
  end
  
  objc_method :print, 'v@:@'
  def print(s)
    NSLog("%@", s)
  end
  
  private
  
  def uh(s)
    s ? CGI.unescapeHTML(s.to_s) : ''
  end
end


class LogPolicy < NSObject
  attr_accessor :owner, :menu, :url_menu, :addr_menu, :member_menu
  attr_accessor :url, :addr, :nick

  objc_method :webView_dragDestinationActionMaskForDraggingInfo, 'I@:@@'
  def webView_dragDestinationActionMaskForDraggingInfo(sender, info)
    WebDragDestinationActionNone
  end
  
  objc_method :webView_contextMenuItemsForElement_defaultMenuItems, '@@:@@@'
  def webView_contextMenuItemsForElement_defaultMenuItems(sender, element, defaultMenu)
    if @url
      @owner.world.menu_controller.url = @url
      @url = nil
      @url_menu.itemArray.to_a.map {|i| i.copy }
    elsif @addr
      @owner.world.menu_controller.addr = @addr
      @addr = nil
      @addr_menu.itemArray.to_a.map {|i| i.copy }
    elsif @nick
      target = @nick
      @nick = nil
      @owner.world.menu_controller.nick = target
      ary = []
      ary << NSMenuItem.alloc.initWithTitle_action_keyEquivalent(target, nil, '')
      ary << NSMenuItem.separatorItem
      ary + @member_menu.itemArray.to_a.map do |i|
        i = i.copy
        modify_member_menu_item(i)
        i
      end
    else
      if @menu
        @menu.itemArray.to_a.map {|i| i.copy }
      else
        []
      end
    end
  end
  
  def modify_member_menu_item(i)
    i.setTag(i.tag.to_i + 500)
    modify_member_menu(i.submenu) if i.hasSubmenu
  end
  
  def modify_member_menu(menu)
    menu.itemArray.to_a.each do |i|
      modify_member_menu_item(i)
    end
  end

  objc_method :webView_decidePolicyForNavigationAction_request_frame_decisionListener, 'v@:@@@@@'
  def webView_decidePolicyForNavigationAction_request_frame_decisionListener(sender, action, request, frame, listener)
    case action.objectForKey(WebActionNavigationTypeKey).intValue.to_i
    when WebNavigationTypeLinkClicked
      listener.ignore
      UrlOpener::openUrl(action.objectForKey(WebActionOriginalURLKey).absoluteString)
    when WebNavigationTypeOther
      listener.use
    else
      listener.ignore
    end
  end
end
