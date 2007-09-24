file = File.join(File.dirname(__FILE__), '../Info.plist')

open(file) do |f|
  next_line = false
  while s = f.gets
    if next_line
      next_line = false
      if s =~ /<string>(.+)<\/string>/
        ver = $1
        print ver
      end
    elsif s =~ /<key>CFBundleVersion<\/key>/
      next_line = true
    end
  end
end
