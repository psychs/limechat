require 'net/http'
require 'cgi'

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
        true
      else
        "http://pastie.caboo.se/pastes/#{result}"
      end
    else
      raise "Error occured (#{response.code}): #{response.body}"
    end
  end
end
