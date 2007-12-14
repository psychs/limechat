# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'cgi'

class PasternakClient < NSObject
  attr_accessor :delegate
  
  TIMEOUT = 10
  REQUEST_URL = 'http://pasternak.superalloy.nl/pastes'
  
  def start(content, nick, syntax='ruby')
    cancel
    @buf = ''
    @response = nil
    params_hash = {
      'paste[username]' => CGI.escape(nick),
      'paste[language]' => CGI.escape(syntax),
      'paste[code]' => CGI.escape(content),
      'wants_url_response' => 'true',
      'patch_style' => 'monkeypatch',
    }
    body = params_hash.inject('') {|v,i| v << "#{i[0].to_s}=#{CGI.escape(i[1].to_s)}&"}.chop
    
    url = NSURL.URLWithString(REQUEST_URL)
    policy = 1  # NSURLRequestReloadIgnoringLocalCacheData
    req = NSMutableURLRequest.requestWithURL_cachePolicy_timeoutInterval(url, policy, TIMEOUT)
    req.setHTTPMethod('POST')
    req.setHTTPBody(NSData.dataWithRubyString(body))
    @conn = NSURLConnection.alloc.initWithRequest_delegate(req, self)
  end
  
  def cancel
    if @conn
      @conn.cancel
      @conn = nil
    end
  end
  
  def connection_didReceiveResponse(conn, res)
    return if @conn != conn
    @response = res
  end

  def connectionDidFinishLoading(conn)
    if @response
      code = @response.statusCode
      if code.to_s =~ /^20[01]$/
        @delegate.pastie_on_success(self, @buf)
      else
        @delegate.pastie_on_error(self, "#{code} #{@response.oc_class.localizedStringForStatusCode(code)}")
      end
    end
    @conn = nil
  end
  
  def connection_didReceiveData(conn, data)
    return if @conn != conn
    @buf << data.rubyString
  end
  
  def connection_didFailWithError(conn, err)
    if @conn == conn
      @delegate.pastie_on_error(self, "#{err.userInfo[:NSLocalizedDescription]}")
    end
    @conn = nil
  end
  
  def connection_willSendRequest_redirectResponse(conn, req, res)
    return nil if @conn != conn
    if res && res.statusCode == 302
      @delegate.pastie_on_success(self, req.URL.to_s)
      @conn = nil
      nil
    else
      req
    end
  end
end
