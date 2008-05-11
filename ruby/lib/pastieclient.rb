# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'cgi'

class PastieClient < NSObject
  attr_accessor :delegate
  
  TIMEOUT = 10
  REQUEST_URL = 'http://pastie.caboo.se/pastes/'
  
  def start(content, nick, syntax='ruby', is_private=true)
    cancel
    @buf = ''
    @response = nil
    body = hash_to_query_string({ :paste => {
      :body => CGI.escape(content),
      :display_name => CGI.escape(nick),
      :parser => syntax,
      :restricted => is_private ? 1 : 0,
      :authorization => 'burger',
    }})
    
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
        #unless @buf.empty?
        #  @buf = PRIVATE_URL + @buf
        #end
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
  
  private
  
  def hash_to_query_string(hash)
    hash.map {|k,v|
      if v.instance_of?(Hash)
        v.map {|sk, sv|
          "#{k}[#{sk}]=#{sv}"
        }.join('&')
      else
        "#{k}=#{v}"
      end
    }.join('&')
  end
end
