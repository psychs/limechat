require "rubygems"
require "test/unit"
require "test/spec"
require "mocha"

require File.expand_path('../../lib/cocoa_gist', __FILE__)

GITHUB_ACCOUNT = { 'login' => 'alloy', 'token' => 'secret' }

describe 'CocoaGist' do
  it "should lazy load the github user info once and return it as a hash" do
    CocoaGist.instance_variable_set(:@credentials, nil)
    CocoaGist.expects(:`).with('git config --global github.user').returns("alloy\n").times(1)
    CocoaGist.expects(:`).with('git config --global github.token').returns("secret\n").times(1)
    
    3.times do
      CocoaGist.credentials.should == GITHUB_ACCOUNT
    end
  end
  
  it "should return an empty hash if no account info was found" do
    CocoaGist.instance_variable_set(:@credentials, nil)
    CocoaGist.stubs(:`).returns('')
    CocoaGist.credentials.should == {}
  end
  
  it "should accept credentials" do
    CocoaGist.set_credentials('psychs', 'top_secret')
    CocoaGist.credentials.should == { 'login' => 'psychs', 'token' => 'top_secret' }
  end
end

describe "A CocoaGist" do
  before do
    CocoaGist.set_credentials(GITHUB_ACCOUNT['login'], GITHUB_ACCOUNT['token'])
    
    @gist = CocoaGist.alloc.init
    @gist.delegate = mock('Delegate')
  end
  
  it "should serialize the parameters" do
    @gist.send(:params, 'the content', 'ruby', true).split('&').sort.should ==
      %w{ file_contents[gistfile1]=the+content  file_ext[gistfile1]=.rb  login=alloy  token=secret private=on }.sort
  end
  
  it "should post the paste contents" do
    @gist.expects(:params).with('the content', 'ruby', true).returns('the parameters')
    
    request = mock('NSMutableURLRequest')
    OSX::NSMutableURLRequest.expects(:requestWithURL_cachePolicy_timeoutInterval).with do |url, policy, timeout|
      url.absoluteString == 'http://gist.github.com/gists' && policy == 1 && timeout == 10
    end.returns(request)
    
    request.expects(:setHTTPMethod).with('POST')
    request.expects(:setHTTPBody).with do |body|
      body.rubyString == 'the parameters'
    end
    
    connection = mock('NSURLConnection')
    OSX::NSURLConnection.any_instance.expects(:initWithRequest_delegate).with(request, @gist).returns(connection)
    
    @gist.start('the content', 'ruby', true)
    @gist.connection.should.be connection
  end
  
  it "should return the request if it there's no response so the process can continue" do
    @gist.connection_willSendRequest_redirectResponse('connection', 'request', nil).should == 'request'
  end
  
  it "should return the request if it's not a redirect so the process can continue" do
    response = mock('Response', :statusCode => 100)
    @gist.connection_willSendRequest_redirectResponse('connection', 'request', response).should == 'request'
  end
  
  it "should stop the process by returning `nil' if the request is a redirect and send the redirect URL to the delegate" do
    url = 'http://gists.example.com/12345'
    request = OSX::NSURLRequest.requestWithURL(OSX::NSURL.URLWithString(url))
    response = mock('Response', :statusCode => 302)
    
    @gist.delegate.expects(:pastie_on_success).with(@gist, url)
    @gist.connection_willSendRequest_redirectResponse('connection', request, response).should == nil
  end
  
  it "should report an error to the delegate" do
    error = mock('NSError', :userInfo => { :NSLocalizedDescription => 'mew' })
    @gist.delegate.expects(:pastie_on_error).with(@gist, 'mew')
    @gist.connection_didFailWithError(nil, error)
  end
  
  it "should cancel the connection if a conncetion exists" do
    @gist.cancel
    @gist.connection.should.be nil
    
    connection = mock('NSURLConnection')
    @gist.instance_variable_set(:@connection, connection)
    connection.expects(:cancel)
    @gist.cancel
    @gist.connection.should.be nil
  end
end
