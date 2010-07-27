require 'pathname'
require 'fileutils'
require 'time'
require 'erb'
require 'pp'

APP_SHORT_NAME = 'LimeChat'
APP_NAME = APP_SHORT_NAME + '.app'
ROOT_PATH = Pathname.new(__FILE__).dirname
RELEASE_BUILD_PATH = ROOT_PATH + 'build/Release' + APP_NAME
README_PATH = ROOT_PATH + 'README.txt'
GPL_PATH = ROOT_PATH + 'GPL.txt'
PACKAGES_PATH = ROOT_PATH + 'Packages'
WEB_PATH = ROOT_PATH + 'web'
TEMPLATES_PATH = WEB_PATH + 'templates'
APPCAST_TEMPLATE_PATH = TEMPLATES_PATH + 'appcast.rxml'
APPCAST_PATH = WEB_PATH + 'limechat_appcast.xml'
TMP_PATH = Pathname.new("/tmp/#{APP_SHORT_NAME}_build_image")


task :default => :build

task :clean do |t|
  sh "rm -rf build"
end

task :build do |t|
  sdk = "10.5"
  sh "xcodebuild -project #{APP_SHORT_NAME}.xcodeproj -target #{APP_SHORT_NAME} -configuration Release -sdk macosx#{sdk} build"
end

task :install => [:clean, :build] do |t|
  sh "killall #{APP_SHORT_NAME}" rescue nil
  sh "rm -rf /Applications/#{APP_NAME}"
  sh "sudo mv #{BUILT_APP_PATH} /Applications/"
  sh "open /Applications/#{APP_NAME}"
end

#task :package => [:clean, :build, :package_app] do |t|
task :package => [:package_app] do |t|
end

task :package_app do |t|
  PACKAGES_PATH.mkpath
  package_path = PACKAGES_PATH + "#{APP_SHORT_NAME}_#{app_version}.tbz"
  package_path.rmtree
  TMP_PATH.rmtree
  TMP_PATH.mkpath
  RELEASE_BUILD_PATH.cptree(TMP_PATH)
  
  doc_path = TMP_PATH + 'doc'
  doc_path.mkpath
  README_PATH.cptree(doc_path)
  GPL_PATH.cptree(doc_path)
  
  rmglob(TMP_PATH + '**/.DS_Store')
  
  Dir.chdir(TMP_PATH) do
    sh "tar jcf #{package_path} *"
  end
  
  TMP_PATH.rmtree
end

task :appcast do |t|
  package_fname = "#{APP_SHORT_NAME}_#{app_version}.tbz"
  package_path = PACKAGES_PATH + package_fname
  stat = File.stat(package_path)
  
  version = app_version
  fsize = stat.size
  ftime = stat.mtime.rfc2822
  updates = parse_commit_log
  dsa_signature = `ruby Frameworks/Sparkle/SigningTools/sign_update.rb #{package_path} etc/dsa_priv.pem`.chomp
  
  APPCAST_PATH.rmtree
  e = ERB.new(File.open(APPCAST_TEMPLATE_PATH).read, nil, '-')
  s = e.result(binding)
  File.open(APPCAST_PATH, 'w') do |f|
    f.write(s)
  end
  
  sh "mate #{WEB_PATH}"
end

task :web do |t|
  rss_templates = ['rss.rxml', 'rss_ja.rxml']
  html_templates = []
  
  change_log = ''
  version = ''
  pubdate = ''
  
  s = File.open(APPCAST_PATH).read
  if m = %r!<ul>.+</ul>!m.match(s)
    change_log = m[0]
  end
  if m = %r!sparkle:version="([^"]+)"!m.match(s)
    version = m[1]
  end
  if m = %r!<pubDate>([^<>]+)</pubDate>!m.match(s)
    pubdate = m[1]
  end
  
  time = Time.rfc2822(pubdate)
  date = time.strftime("%Y.%m.%d")
  
  rss_templates.each do |fname|
    template_path = TEMPLATES_PATH + fname
    out_path = WEB_PATH + fname.gsub('.rxml', '.xml')
    
    out_path.rmtree
    e = ERB.new(File.open(template_path).read, nil, '-')
    s = e.result(binding)
    File.open(out_path, 'w') do |f|
      f.write(s)
    end
  end
  
  html_templates.each do |fname|
    template_path = TEMPLATES_PATH + fname
    out_path = WEB_PATH + fname.gsub('.rhtml', '.html')
    
    out_path.rmtree
    e = ERB.new(File.open(template_path).read, nil, '-')
    s = e.result(binding)
    File.open(out_path, 'w') do |f|
      f.write(s)
    end
  end
end


class CommitLog
  attr_accessor :hash, :merge, :author, :date
  attr_reader :lines
  
  def initialize
    @lines = []
  end
  
  def add_line(line)
    @lines << line
  end
  
  def release_version
    ary = @lines.select {|e| e =~ /^released (\d+\.\d+)$/i }
    if ary
      $1
    else
      nil
    end
  end
  
  def one_line
    s = ''
    @lines.each do |e|
      s << e
      s << ' '
    end
    s.chop
  end
  
  def inspect
    "<CommitLog #{hash[0...6]} #{author} #{date}>"
  end
end

def parse_commit_log
  updates = []
  commit = nil
  
  log = `git log | head -n 1000`
  
  log.each_line do |s|
    s.chomp!
    if s =~ /^commit\s+/
      if commit
        updates << commit
      end
      commit = CommitLog.new
      commit.hash = $~.post_match
    elsif s =~ /^Author:\s*/
      commit.author = $~.post_match
    elsif s =~ /^Date:\s*/
      commit.date = $~.post_match
    elsif s =~ /^Merge:\s*/
      commit.merge = $~.post_match
    elsif s =~ /^\s*$/
      ;
    elsif s =~ /^\s+/
      commit.add_line($~.post_match)
    end
  end
  
  updates << commit
  
  ver = app_version
  first = 0
  last = 0
  updates.each_with_index do |e,i|
    rel = e.release_version
    if rel
      if rel == ver
        first = i + 1
      else
        last = i
        break
      end
    end
  end
  
  updates = updates[first...last]
  updates.map {|e| e.one_line }
end

module Util
  def app_version
    file = ROOT_PATH + 'Others/Info.plist'
    file.open do |f|
      next_line = false
      while s = f.gets
        if next_line
          next_line = false
          if s =~ /<string>(.+)<\/string>/
            return $1
          end
        elsif s =~ /<key>CFBundleShortVersionString<\/key>/
          next_line = true
        end
      end
    end
    nil
  end
  
  def rmglob(path)
    FileUtils.rm_rf(Dir.glob(path.to_s))
  end
end
include Util

class Pathname
  def rmtree
    FileUtils.rm_rf(to_s)
  end
  
  def cptree(to)
    FileUtils.cp_r(to_s, to.to_s)
  end
end
