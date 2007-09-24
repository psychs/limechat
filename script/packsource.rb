require 'fileutils'

source_path = File.join(File.dirname(__FILE__), '../')
dest_path = File.expand_path('~/Desktop') + '/'
tmp_path = dest_path + 'limechat_tmp/'

FileUtils.rm_rf(tmp_path)
FileUtils.cp_r(source_path, tmp_path)

FileUtils.rm_rf(Dir.glob(tmp_path + '**/*~.nib'))
FileUtils.rm_rf(Dir.glob(tmp_path + '**/._*'))
FileUtils.rm_rf(Dir.glob(tmp_path + 'build'))
FileUtils.rm_rf(Dir.glob(tmp_path + '**/.svn'))
FileUtils.rm_rf(Dir.glob(tmp_path + '**/.DS_Store'))

vercmd = File.join(File.dirname(__FILE__), 'getver.rb')
ver = `ruby #{vercmd}`
file = "#{dest_path}LimeChat_#{ver}.zip"
FileUtils.rm_f(file)

Dir.chdir(tmp_path)
cmd = "zip -qr #{file} *"
system(cmd)

FileUtils.rm_rf(tmp_path)
