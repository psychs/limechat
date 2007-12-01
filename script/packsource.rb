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

source = Pathname.new(__FILE__).dirname.parent
dest = Pathname.new('~/Desktop').expand_path
tmp = dest + 'limechat_tmp'

tmp.rmtree
source.cptree(tmp)

rmglob(tmp + 'build')
rmglob(tmp + '**/.svn')
rmglob(tmp + '**/.DS_Store')
rmglob(tmp + '**/*~.nib')
rmglob(tmp + '**/._*')

vercmd = Pathname.new(__FILE__).dirname + 'getver.rb'
ver = `ruby #{vercmd}`
file = dest + "LimeChat_#{ver}.zip"
Dir.chdir(tmp)
system("zip -qr #{file} *")

tmp.rmtree
