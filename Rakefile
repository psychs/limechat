task :default => :build

task :build do |t|
  sh "xcodebuild -target LimeChat -configuration Release build"
end

task :install do |t|
  sh "xcodebuild -target LimeChat -configuration Release install DSTROOT=/"
end
