require 'pathname'
require 'fileutils'

class Pathname
  def rmtree
    FileUtils.rm_rf(to_s)
  end
  
  def cptree(to)
    FileUtils.cp_r(to_s, to.to_s)
  end
end

appshortname = 'LimeChat'
appname = appshortname + '.app'
appver = Pathname.new(__FILE__).dirname + 'appversion.rb'
ver = `ruby #{appver}`
imagename = "#{appshortname}_#{ver}.dmg"

root = Pathname.new(__FILE__).dirname.parent
app = root + 'build/Release' + appname
doc = root + 'doc'
desktop = Pathname.new('~/Desktop').expand_path
tmp = desktop + 'build_dmg_tmp'
appdoc = tmp + appname + 'Contents'
image = desktop + imagename

image.rmtree
tmp.rmtree
tmp.mkpath
app.cptree(tmp)

system "ln -s /Applications #{tmp}"
doc.cptree(tmp)
doc.cptree(appdoc)

system "hdiutil create -srcfolder #{tmp} -volname #{appshortname} #{image}"

tmp.rmtree
