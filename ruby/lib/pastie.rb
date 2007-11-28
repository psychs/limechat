require 'net/http'
require 'cgi'

class PastieClient < OSX::NSObject
  include OSX
  attr_accessor :delegate
  attr_accessor :uid, :cid

  TEMPLATE = <<-EOL
<?xml version="1.0" encoding="UTF-8"?>
<paste>
<body>%s</body>
<parser>%s</parser>
<authorization>burger</authorization>
</paste>
EOL

  TIMEOUT = 10.0
  TARGET_URL = 'http://pastie.caboo.se/pastes/'
  
  def start(content, syntax='ruby')
    @buf = ''
    body = sprintf(TEMPLATE, CGI.escapeHTML(content), syntax)
    
    url = NSURL.URLWithString(TARGET_URL)
    req = NSMutableURLRequest.requestWithURL_cachePolicy_timeoutInterval(url, NSURLRequestReloadIgnoringLocalCacheData, TIMEOUT)
    req.setHTTPMethod('POST')
    req.setValue_forHTTPHeaderField('application/xml', 'Content-Type')
    req.setValue_forHTTPHeaderField('application/xml', 'Accept')
    req.setHTTPBody(NSData.dataWithRubyString(body))
    @conn = NSURLConnection.alloc.initWithRequest_delegate(req, self)
  end
  
  def cancel
    @conn.cancel if @conn
  end
  
  def connection_didReceiveResponse(conn, res)
    @response = res
  end

  def connectionDidFinishLoading(conn)
    code = @response.statusCode
    if code.to_s =~ /^20[01]$/
      unless @buf.empty?
        @buf = TARGET_URL + @buf
      end
      @delegate.pastie_on_success(self, @buf)
    else
      @delegate.pastie_on_error(self, "#{code} #{@response.oc_class.localizedStringForStatusCode(code)}")
    end
    @conn = nil
  end
  
  def connection_didFailWithError(conn, err)
    @delegate.pastie_on_error(self, "#{err.userInfo[:NSLocalizedDescription]}")
    @conn = nil
  end
  
  def connection_didReceiveData(conn, data)
    @buf << data.rubyString
  end
end


=begin
class PastieClient

TEMPLATE = <<-EOL
<?xml version="1.0" encoding="UTF-8"?>
<paste>
<body>%s</body>
<parser>%s</parser>
<authorization>burger</authorization>
</paste>
EOL
  
  def paste(content, syntax='ruby')
    body = sprintf(TEMPLATE, CGI.escapeHTML(content), syntax)
    @connection = Net::HTTP.new('pastie.caboo.se', 80)
    response = @connection.post('/pastes/' , body, 'Content-Type' => 'application/xml', 'Accept' => 'application/xml')
    if response.code =~ /20[01]/
      result = response.body
      if result.empty?
        nil
      else
        "http://pastie.caboo.se/pastes/#{result}"
      end
    else
      raise "Error occured (#{response.code}): #{response.body}"
    end
  end
end
=end
