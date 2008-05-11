ary = []

open('DerivedCoreProperties.txt') do |f|
  while s = f.gets
    if s =~ /\A([\dA-F\.]+) *; Alphabetic # L[^ ][\[\]\d ]+(.*)\n\z/
      range, comment = $1, $2
      case comment
      when /CJK/,/HANGUL/,/KATAKANA/,/HIRAGANA/,/IDEOGRAPH/,/KANA/,/MASU MARK/,/BOPOMOFO LETTER/
        # ignore
      else
        ary << range
      end
    end
  end
end

res = []

ary.each do |i|
  case i
  when /^([\da-fA-F]+)\.+([\da-fA-F]+)$/
    left, right = $1.to_i(16), $2.to_i(16)
  when /^[\da-fA-F]+$/
    left = right = $&.to_i(16)
  else
    raise 'not matching: ' + i
  end
  
  # combine adjacent ranges
  last = res.last
  if last
    tail = last[1]
    if tail+1 == left
      last[1] = right
      next
    end
  end
  
  res << [left, right]
end

def print_table(ary, name)
  puts "  #{name} = ["
  ary.each do |i|
    if i[0] == i[1]
      printf("    0x%04x,\n", i[0])
    else
      printf("    0x%04x..0x%04x,\n", i[0], i[1])
    end
  end
  puts '  ]'
end


# generate code

puts <<-EOM
module UnicodeUtil
  
EOM

ary = []

v = 0x300
cur, res = res.partition {|i| i[0] < v || i[1] < v}
print_table(cur, 'TABLE1')
ary << [cur, 'TABLE1']
v = 0x1000
cur, res = res.partition {|i| i[0] < v || i[1] < v}
print_table(cur, 'TABLE2')
ary << [cur, 'TABLE2']
v = 0x2000
cur, res = res.partition {|i| i[0] < v || i[1] < v}
print_table(cur, 'TABLE3')
ary << [cur, 'TABLE3']
v = 0x3000
cur, res = res.partition {|i| i[0] < v || i[1] < v}
print_table(cur, 'TABLE4')
ary << [cur, 'TABLE4']
v = 0xb000
cur, res = res.partition {|i| i[0] < v || i[1] < v}
print_table(cur, 'TABLE5')
ary << [cur, 'TABLE5']
v = 0x10000
cur, res = res.partition {|i| i[0] < v || i[1] < v}
print_table(cur, 'TABLE6')
ary << [cur, 'TABLE6']
print_table(res, 'OTHERS_TABLE')
ary << [res, 'OTHERS_TABLE']

puts <<-EOM

  def alphabetic?(code)
    table = case code
EOM
ary.each do |i|
  table, name = i
  first = table.first.first
  last = table.last.last
  printf("    when 0x%x..0x%x\n", first, last)
  puts "      #{name}"
end
puts <<-EOM
    else
      nil
    end
    
    return false unless table
    
    left = 0
    right = table.size - 1
    while left <= right
      center = (left + right) / 2
      v = table[center]
      if Range === v
        return true if v === code
        if code < v.begin
          right = center - 1
          next
        else
          left = center + 1
          next
        end
      else
        return true if v == code
        if code < v
          right = center - 1
          next
        else
          left = center + 1
          next
        end
      end
    end
    false
  end
  
  extend self
end
EOM
