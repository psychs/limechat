require 'pathname'
require 'fileutils'

APP_SHORT_NAME = 'LimeChat'
APP_NAME = APP_SHORT_NAME + '.app'
ROOT_PATH = Pathname.new(__FILE__).dirname
DESKTOP_PATH = Pathname.new('~/Desktop').expand_path
TMP_PATH = Pathname.new("/tmp/#{APP_SHORT_NAME}_build_image")
BUILD_APP_PATH = ROOT_PATH + 'build/Release' + APP_NAME
DOC_PATH = ROOT_PATH + 'doc'

desc "Same as :build"
task :default => :build

desc "Build a release version"
task :build do |t|
  sh "xcodebuild -target LimeChat -configuration Release build"
end

desc "Install to /"
task :install do |t|
  sh "xcodebuild -target LimeChat -configuration Release install DSTROOT=/"
end

desc "Clean all build files"
task :clean do |t|
  sh "rm -rf build"
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
end

desc "Create a release package"
task :package => [:package_app, :package_source] do |t|
end

task :package_app => :build do |t|
	DMG_PATH = DESKTOP_PATH + "#{APP_SHORT_NAME}_#{app_version}.dmg"
	DMG_PATH.rmtree
	TMP_PATH.rmtree
	TMP_PATH.mkpath
	BUILD_APP_PATH.cptree(TMP_PATH)
	
	DOC_PATH.cptree(TMP_PATH)
	rmglob(TMP_PATH + '**/.svn')
	rmglob(TMP_PATH + '**/.DS_Store')
	
	sh "ln -s /Applications #{TMP_PATH}"
	sh "hdiutil create -srcfolder #{TMP_PATH} -volname #{APP_SHORT_NAME} #{DMG_PATH}"
	
	TMP_PATH.rmtree
end

task :package_source do |t|
	SOURCE_ZIP_PATH = DESKTOP_PATH + "#{APP_SHORT_NAME}_#{app_version}.zip"
	SOURCE_ZIP_PATH.rmtree
	TMP_PATH.rmtree
	
	ROOT_PATH.cptree(TMP_PATH)
	
	rmglob(TMP_PATH + 'build')
	rmglob(TMP_PATH + 'etc')
	rmglob(TMP_PATH + 'script')
	rmglob(TMP_PATH + 'web')
	rmglob(TMP_PATH + '**/.gitignore')
	rmglob(TMP_PATH + '**/.svn')
	rmglob(TMP_PATH + '**/.DS_Store')
	rmglob(TMP_PATH + '**/*~.nib')
	rmglob(TMP_PATH + '**/._*')
	
	Dir.chdir(TMP_PATH) do
		sh "zip -qr #{SOURCE_ZIP_PATH} *"
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
