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

def rmglob(path)
  FileUtils.rm_rf(Dir.glob(path.to_s))
end

appver = Pathname.new(__FILE__).dirname + 'appversion.rb'
ver = `ruby #{appver}`

source = Pathname.new(__FILE__).dirname.parent
desktop = Pathname.new('~/Desktop').expand_path
tmp = desktop + 'build_source_tmp'

tmp.rmtree
source.cptree(tmp)

rmglob(tmp + 'build')
rmglob(tmp + '**/.svn')
rmglob(tmp + '**/.DS_Store')
rmglob(tmp + '**/*~.nib')
rmglob(tmp + '**/._*')

Dir.chdir(tmp)
file = desktop + "LimeChat_#{ver}.zip"
file.rmtree
system "zip -qr #{file} *"

tmp.rmtree
