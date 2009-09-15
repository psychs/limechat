require 'pathname'
require 'fileutils'
require 'rake/testtask'

APP_SHORT_NAME = defined?(MACRUBY_VERSION) ? 'MRLimeChat' : 'LimeChat'
APP_NAME = APP_SHORT_NAME + '.app'
ROOT_PATH = Pathname.new(__FILE__).dirname
DESKTOP_PATH = Pathname.new('~/Desktop').expand_path
TMP_PATH = Pathname.new("/tmp/#{APP_SHORT_NAME}_build_image")
BUILD_APP_PATH = ROOT_PATH + 'build/Release' + APP_NAME
DOC_PATH = ROOT_PATH + 'doc'


task :default => :build

task :clean do |t|
  sh "rm -rf build"
end

task :build do |t|
  build('10.5')
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
end

task :package => [:package_app_10_5, :package_app_10_6, :package_source] do |t|
end

task :package_app_10_5 => :clean do |t|
  sdk = '10.5'
  build(sdk)
  embed_framework(sdk)
  package(sdk)
end

task :package_app_10_6 => :clean do |t|
  sdk = '10.6'
  build(sdk)
  embed_framework(sdk)
  package(sdk)
end

task :package_source do |t|
  package_source
end


def build(sdk)
  sh "xcodebuild -project #{APP_SHORT_NAME}.xcodeproj -target #{APP_SHORT_NAME} -configuration Release -sdk macosx#{sdk} build"
end

def embed_framework(sdk)
  sh %Q|/usr/bin/ruby -r etc/package_builder -e "PackageBuilder.build('#{BUILD_APP_PATH}', '#{sdk}')"|
end

def package(sdk)
	zip_path = DESKTOP_PATH + "#{APP_SHORT_NAME}_#{app_version}_#{sdk}.zip"
	zip_path.rmtree
	TMP_PATH.rmtree
	TMP_PATH.mkpath
	BUILD_APP_PATH.cptree(TMP_PATH)
	
	DOC_PATH.cptree(TMP_PATH)
	rmglob(TMP_PATH + '**/ChangeLog.txt')
	rmglob(TMP_PATH + '**/.svn')
	rmglob(TMP_PATH + '**/.DS_Store')
	
	Dir.chdir(TMP_PATH) do
		sh "zip -qr #{zip_path} *"
	end
	
	TMP_PATH.rmtree
end

def package_source
	source_zip_path = DESKTOP_PATH + "#{APP_SHORT_NAME}_#{app_version}.zip"
	source_zip_path.rmtree
	TMP_PATH.rmtree
	
	ROOT_PATH.cptree(TMP_PATH)
	
	rmglob(TMP_PATH + 'build')
	rmglob(TMP_PATH + 'etc')
	rmglob(TMP_PATH + 'script')
	rmglob(TMP_PATH + 'web')
	rmglob(TMP_PATH + '*.tmproj')
	rmglob(TMP_PATH + 'MRLimeChat.xcodeproj')
	rmglob(TMP_PATH + 'LimeChat.xcodeproj/*.mode1*')
	rmglob(TMP_PATH + 'LimeChat.xcodeproj/*.pbxuser')
	rmglob(TMP_PATH + '**/*.tm_build_errors')
	rmglob(TMP_PATH + '**/.gitignore')
	rmglob(TMP_PATH + '**/.svn')
	rmglob(TMP_PATH + '**/.DS_Store')
	rmglob(TMP_PATH + '**/*~.nib')
	rmglob(TMP_PATH + '**/._*')
	
	Dir.chdir(TMP_PATH) do
		sh "zip -qr #{source_zip_path} *"
	end
	
	TMP_PATH.rmtree
end


module Util
	def app_version
		file = ROOT_PATH + 'Info.plist'
		file.open do |f|
		  next_line = false
		  while s = f.gets
		    if next_line
		      next_line = false
		      if s =~ /<string>(.+)<\/string>/
		        return $1
		      end
		    elsif s =~ /<key>CFBundleVersion<\/key>/
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
