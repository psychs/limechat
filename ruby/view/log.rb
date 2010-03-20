# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'cgi'
require 'uri'
require 'logrenderer'

class LogLine
  attr_accessor :time, :place, :nick, :body
  attr_accessor :line_type, :member_type
  attr_accessor :nick_info, :click_info, :identified, :nick_color_number

  def initialize(time, place, nick, body, line_type=:system, member_type=:normal, nick_info=nil, click_info=nil, identified=nil, nick_color_number=nil)
    @time = time
    @place = place
    @nick = nick
    @body = body
    @line_type = line_type
    @member_type = member_type
    @nick_info = nick_info
    @click_info = click_info
    @identified = identified
    @nick_color_number = nick_color_number
  end
end


class LogController < NSObject
  attr_accessor :world
  attr_writer :unit, :channel, :menu, :url_menu, :addr_menu, :chan_menu, :member_menu, :keyword, :theme, :override_font
  attr_reader :view

  def initialize
    @bottom = true
    @lines = []
    @line_number = 0
    @count = 0
    @loaded = false
    @max_lines = 300
    @highlight_line_numbers = []
  end

  def setup(console, initial_bgcolor)
    @loaded = false
    @console = console
    @policy = LogPolicy.alloc.init
    @policy.owner = self
    @policy.menu = @menu
    @policy.url_menu = @url_menu
    @policy.addr_menu = @addr_menu
    @policy.chan_menu = @chan_menu
    @policy.member_menu = @member_menu
    @sink = LogScriptEventSink.alloc.init
    @sink.owner = self
    @sink.policy = @policy
    @view.release if @view
    @view = LogView.alloc.initWithFrame(NSZeroRect)
    @view.setBackgroundColor(initial_bgcolor) if @view.respondsToSelector('setBackgroundColor:') # new in Leopard
    @view.setFrameLoadDelegate(self)
    @view.setUIDelegate(@policy)
    @view.setPolicyDelegate(@policy)
    #@view.setResourceLoadDelegate(self)
    @view.key_delegate = self
    @view.resize_delegate = self
    @view.setAutoresizingMask(NSViewWidthSizable | NSViewHeightSizable)
    @view.mainFrame.loadHTMLString_baseURL(initial_document, @theme.log.baseurl)
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
    body[:scrollTop] = 0
  end

  def moveToBottom
    return unless @loaded
    doc = @view.mainFrame.DOMDocument
    return unless doc
    body = doc.body
    body[:scrollTop] = body[:scrollHeight]
  end

  BOTTOM_EPSILON = 20

  def viewing_bottom?
    return true unless @loaded
    doc = @view.mainFrame.DOMDocument
    return true unless doc
    body = doc.body
    viewheight = @view.frame.height.to_i rescue 0
    scrollheight = body[:scrollHeight]
    scrolltop = body[:scrollTop]
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

  def print(line, unit, use_keyword=true)
    body, key = build_body(line, unit, use_keyword)

    unless @loaded
      @lines << [line, unit, use_keyword]
      return key
    end

    s = ''
    s << %|<span class="time">#{h(line.time)}</span>| if line.time
    s << %|<span class="place">#{h(line.place)}</span>| if line.place
    if line.nick
      s << %|<span class="sender" type="#{line.member_type}"|
      s << %| oncontextmenu="on_nick_contextmenu()"| unless @console
      s << %| identified="#{!!line.identified}"|
      s << %| colornumber="#{line.nick_color_number}"| if line.member_type == :normal
      s << %| first="#{line.nick_info != @prev_nick_info}"| if line.nick_info
      s << %|>#{h(line.nick)}</span>|
    end

    if m = %r!(http://[a-zA-Z0-9_\.\/]*\.(jpg|jpeg|png|gif))!.match(body)
      url = m[1]
      s << %[<span class="message" type="#{line.line_type}">#{body}
             <br>
             <a href="#{url}"><img src="#{url}" class="inlineimage"/></a>
             </span>\n]
    else
      s << %[<span class="message" type="#{line.line_type}">#{body}</span>\n]
    end

    @prev_nick_info = line.nick_info

    attrs = {}
    alternate = @line_number % 2 == 0 ? 'even' : 'odd'
    attrs['alternate'] = alternate
    klass = 'line'
    case line.line_type
    when :privmsg,:notice,:action
      klass << ' text'
    else
      klass << ' event'
    end
    attrs['class'] = klass
    attrs['type'] = line.line_type.to_s
    attrs['highlight'] = "#{!!key}"
    attrs['nick'] = line.nick_info if line.nick_info
    if @console
      if line.click_info
        attrs['clickinfo'] = line.click_info
        attrs['ondblclick'] = 'on_dblclick()'
      end
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
    if e
      doc.body.removeChild(e)
    end
  end
  
  def go_to_mark
    return unless @loaded
    doc = @view.mainFrame.DOMDocument
    return unless doc
    e = doc.getElementById('mark')
    if e
      y = 0
      t = e
      while t
        if t.is_a?(DOMHTMLElement)
          y += t[:offsetTop]
        end
        t = t.parentNode
      end
      doc.body[:scrollTop] = y - 40
    end
  end

  def reload_theme
    return unless @loaded
    doc = @view.mainFrame.DOMDocument
    return unless doc
    body = doc.body
    @html = body.innerHTML
    @scroll_bottom = viewing_bottom?
    @scroll_top = body[:scrollTop]
    #setup(@console, style)
    @view.mainFrame.loadHTMLString_baseURL(initial_document, @theme.log.baseurl)
    @scroller.setNeedsDisplay(true)
  end

	def clear
    return unless @loaded
    doc = @view.mainFrame.DOMDocument
    return unless doc
    body = doc.body
    @html = nil
    @loaded = false
    @view.mainFrame.loadHTMLString_baseURL(initial_document, @theme.log.baseurl)
    @scroller.setNeedsDisplay(true)
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
    @js[:app] = @sink
  end

  objc_method :webView_didFinishLoadForFrame, 'v@:@@'
  def webView_didFinishLoadForFrame(sender, frame)
    @loaded = true
    setup_scroller
    if @html
      body = @view.mainFrame.DOMDocument.body
      body.innerHTML = @html
      if @scroll_bottom
        moveToBottom
      elsif @scroll_top
        body[:scrollTop] = @scroll_top
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
          while (t && !(t.tagName == 'DIV' && t.className.match(/^line /))) {
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
        function on_channel_contextmenu() {
          var t = event.target
          app.setChan(t.innerHTML)
        }
      EOM
      @js.evaluateWebScript(script)
    end

    if @theme.js.content
      @js.evaluateWebScript(@theme.js.content)
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

  def scroller_markedPosition(sender)
    ary = []
    doc = @view.mainFrame.DOMDocument
    if doc
      @highlight_line_numbers.each do |n|
        e = doc.getElementById("line#{n}")
        if e
          ary << e[:offsetTop] + e[:offsetHeight] / 2.0
        end
      end
    end
    ary
  end

  def scroller_markColor(sender)
    @theme.other.log_scroller_highlight_color
  end

  private

  def setup_scroller
    view = @view.mainFrame.frameView.subviews.find {|i| i.is_a?(NSScrollView) }
    if view
      view.setHasHorizontalScroller(false)
      view.setAllowsHorizontalScrolling(false)
      old = view.verticalScroller
      if old && !old.is_a?(MarkedScroller)
        # new scroller needs to be initialized with enough frame
        @scroller = MarkedScroller.alloc.initWithFrame(NSRect.new(-16,-64,16,64))
        @scroller.dataSource = self
        @scroller.setFloatValue_knobProportion(old.floatValue, old.knobProportion)
        view.setVerticalScroller(@scroller)
      end
    end
  rescue
    p $!
  end

  def build_body(line, unit, use_keyword)
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
      if unit && @keyword.current_nick && !unit.mynick.empty?
        like += [unit.mynick]
      end
    else
      like = dislike = nil
    end

    LogRenderer.render_body(line.body, like, dislike, @keyword.whole_line, @keyword.matching_method == Preferences::Keyword::MATCH_EXACT_WORD)
  end

  def h(s)
    s ? LogRenderer.escape_str(s) : ''
  end

  def remove_first_line(n=1)
    return unless @loaded
    return if n <= 0
    return if @count <= 0
    doc = @view.mainFrame.DOMDocument
    return unless doc
    body = doc.body

    # remember scroll top
    top = body[:scrollTop]
    delta = 0

    last_line_id = nil
    n.times do
      node = body.firstChild
      if DOMHTMLElement === node && node.tagName.to_s.downcase == 'hr'
        # the first node is the mark
        next_sibling = node.nextSibling
        delta += next_sibling[:offsetTop] - node[:offsetTop] if next_sibling
        body.removeChild(node)
        node = next_sibling
      end
      next_sibling = node.nextSibling
      delta += next_sibling[:offsetTop] - node[:offsetTop] if next_sibling
      last_line_id = node['id']
      body.removeChild(node)
    end

    # scroll back by delta
    if delta > 0
      body[:scrollTop] = top - delta
    end

    # updating highlight line numbers
    if last_line_id && last_line_id =~ /\d+$/
      num = $&.to_i
      first = @highlight_line_numbers[0]
      if first && first <= num
        @highlight_line_numbers.reject! {|i| i <= num}
      end
    end

    @count -= n
    @scroller.setNeedsDisplay(true) if @scroller
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

    if attrs['highlight'] == 'true'
      @highlight_line_numbers << @line_number
    end
    @scroller.setNeedsDisplay(true) if @scroller
    restore_position
  end

  def initial_document
    body_class = @console ? 'console' : 'normal'
    if @channel
      body_attrs = %| type="#{@channel.type}"|
      body_attrs << %| channelname="#{h(@channel.name)}"| if @channel.channel?
    elsif @console
      body_attrs = %| type="console"|
    else
      body_attrs = %| type="server"|
    end

    style = @theme.log.content || ''
    if @override_font
      name = @override_font[0]
      size = @override_font[1] * (72.0 / 96.0)
      override_style = <<-EOM
        html, body, body[type], body.normal, body.console {
          font-family: '#{name}';
          font-size: #{size}pt;
        }
      EOM
    else
      override_style = ''
    end

    doc = <<-EOM
      <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
      <html class="#{body_class}" #{body_attrs}>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <meta http-equiv="Content-Script-Type" content="text/javascript">
        <meta http-equiv="Content-Style-Type" content="text/css">
        <title>LimeChat Log</title>
        <style>#{DEFAULT_CSS}</style>
        <style><!-- #{style} --></style>
        <style>#{override_style}</style>
      </head>
      <body class="#{body_class}" #{body_attrs}></body>
      </html>
    EOM

    doc
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
    img { border: 1px solid #aaa; vertical-align: top; }
    object { vertical-align: top; }
    hr { margin: 0.5em 2em; }
    .line { margin: 0 -4px; padding: 0 4px 1px 4px; }
    .line[alternate=even] {}
    .line[alternate=odd] {}
    .line[type=action] .sender:before {
      content: "• ";
      white-space: nowrap;
    }
    .inlineimage {
      margin-top: 10px;
      margin-bottom: 15px;
      margin-left: 40px;
      max-width: 400px;
      max-height: 300px;
      -webkit-box-shadow:5px 5px 2px #888;
    }
    .url { word-break: break-all; }
    .address { text-decoration: underline; word-break: break-all; }
    .highlight { color: #f0f; font-weight: bold; }
    .time { color: #048; }
    .place { color: #008; }
    .sender[type=myself] { color: #66a; }
    .sender[type=normal] { color: #008; }
    .message[type=system] { color: #080; }
    .message[type=error] { color: #f00; font-weight: bold; }
    .message[type=reply] { color: #088; }
    .message[type=error_reply] { color: #f00; }
    .message[type=dcc_send_send] { color: #088; }
    .message[type=dcc_send_receive] { color: #00c; }
    .message[type=privmsg] {}
    .message[type=notice] { color: #888; }
    .message[type=action] {}
    .message[type=join] { color: #080; }
    .message[type=part] { color: #080; }
    .message[type=kick] { color: #080; }
    .message[type=quit] { color: #080; }
    .message[type=kill] { color: #080; }
    .message[type=nick] { color: #080; }
    .message[type=mode] { color: #080; }
    .message[type=topic] { color: #080; }
    .message[type=invite] { color: #080; }
    .message[type=wallops] { color: #080; }
    .message[type=debug_send] { color: #aaa; }
    .message[type=debug_receive] { color: #444; }

    .effect[color-number='0'] { color: #fff; }
    .effect[color-number='1'] { color: #000; }
    .effect[color-number='2'] { color: #008; }
    .effect[color-number='3'] { color: #080; }
    .effect[color-number='4'] { color: #f00; }
    .effect[color-number='5'] { color: #800; }
    .effect[color-number='6'] { color: #808; }
    .effect[color-number='7'] { color: #f80; }
    .effect[color-number='8'] { color: #ff0; }
    .effect[color-number='9'] { color: #0f0; }
    .effect[color-number='10'] { color: #088; }
    .effect[color-number='11'] { color: #0ff; }
    .effect[color-number='12'] { color: #00f; }
    .effect[color-number='13'] { color: #f0f; }
    .effect[color-number='14'] { color: #888; }
    .effect[color-number='15'] { color: #ccc; }
    .effect[bgcolor-number='0'] { background-color: #fff; }
    .effect[bgcolor-number='1'] { background-color: #000; }
    .effect[bgcolor-number='2'] { background-color: #008; }
    .effect[bgcolor-number='3'] { background-color: #080; }
    .effect[bgcolor-number='4'] { background-color: #f00; }
    .effect[bgcolor-number='5'] { background-color: #800; }
    .effect[bgcolor-number='6'] { background-color: #808; }
    .effect[bgcolor-number='7'] { background-color: #f80; }
    .effect[bgcolor-number='8'] { background-color: #ff0; }
    .effect[bgcolor-number='9'] { background-color: #0f0; }
    .effect[bgcolor-number='10'] { background-color: #088; }
    .effect[bgcolor-number='11'] { background-color: #0ff; }
    .effect[bgcolor-number='12'] { background-color: #00f; }
    .effect[bgcolor-number='13'] { background-color: #f0f; }
    .effect[bgcolor-number='14'] { background-color: #888; }
    .effect[bgcolor-number='15'] { background-color: #ccc; }
  EOM
end


class LogScriptEventSink < NSObject
  attr_accessor :owner, :policy

  EXPORTED_METHODS = %w|onDblClick: shouldStopDoubleClick: setUrl: setAddr: setNick: setChan: print:|

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

  objc_method :setChan, 'v@:@'
  def setChan(s)
    @policy.chan = uh(s)
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
  attr_accessor :owner, :menu, :url_menu, :addr_menu, :member_menu, :chan_menu
  attr_accessor :url, :addr, :nick, :chan

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
    elsif @chan
      target = @chan
      @chan = nil
      @owner.world.menu_controller.chan = target
      @chan_menu.itemArray.to_a.map {|i| i.copy}
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
