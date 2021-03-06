require 'json'

def hyphenate(name)
  name.gsub(/([a-z])([A-Z])/, '\1-\2').downcase
end

def expression(node, indent)
  if node['type'] == 'choice'
    puts ''.ljust(indent) + 'Choice:'
    node['alternatives'].each do |alternative|
      expression(alternative, indent+2)
    end
  elsif node['type'] == 'rule_ref'
    puts ''.ljust(indent) + 'N: ' + hyphenate(node['name'])
  elsif node['type'] == 'literal'
    puts ''.ljust(indent) + 'T: ' + node['value']
  elsif node['type'] == 'any'
    puts ''.ljust(indent) + 'T: any'
  elsif node['type'] == 'class'
    text = node['rawText'].sub('[^', '[').sub(']i', ']')
    if node['inverted']
      puts ''.ljust(indent) + 'T: any except ' + text
    elsif text =~ /^\[\\?(.)\\?(.)\]$/
      puts ''.ljust(indent) + 'Choice:'
      puts ''.ljust(indent) + "  T: #{$1}"
      puts ''.ljust(indent) + "  T: #{$2}"
    else
      puts ''.ljust(indent) + 'T: any of ' + text
    end
  elsif node['type'] == 'action'
    expression(node['expression'], indent)
  elsif node['type'] == 'labeled'
    expression(node['expression'], indent)
  elsif node['type'] == 'optional'
    puts ''.ljust(indent) + 'Optional:'
    expression(node['expression'], indent+2)
  elsif node['type'] == 'zero_or_more'
    puts ''.ljust(indent) + 'ZeroOrMore:'
    expression(node['expression'], indent+2)
  elsif node['type'] == 'one_or_more'
    puts ''.ljust(indent) + 'OneOrMore:'
    expression(node['expression'], indent+2)
  elsif node['type'] == 'sequence'
    puts ''.ljust(indent) + 'Sequence:'
    node['elements'].each do |element|
      expression(element, indent+2)
    end
  elsif node['type'] == 'semantic_and'
  else
    puts ''.ljust(indent) + '??? ' + node['type'] + ' ???'
  end
end

puts File.read('header.in')

grammar = File.read('url.pegjs')

prose = Hash[grammar.scan(/^\/\*\n?(.*?)\*\/\s*(\w+)/m).map { |text, name|
  indent = text.split("\n").map {|line| line[/^ */]}.reject(&:empty?).min
  text.gsub!(/@([A-Z][-\w]+)'?/) do
    "<code class=grammar-rule><a href=##{hyphenate $1}>#{hyphenate $1}</a></code>"
  end
  text.gsub!(/\$([a-z](\.\w|\w)*)/) do
    "<code>#{$1}</code>"
  end
  text.gsub!(/"( |\S+)"/) do
    "\"<code>#{$1}</code>\""
  end
  text.gsub!(/(U\+[0-9a-fA-F]{4})/) do
    "<code>#{$1.upcase}</code>"
  end
  text.gsub!(/(0x[0-9a-fA-F]{2}+)/) do
    "<code>#{$1.upcase.sub('0X', '0x')}</code>"
  end
  text.gsub!(/\b(\d+)\b/) do
    "<code>#{$1}</code>"
  end
  text.gsub!(/`(.*?)`/) do
    "<code>#{$1.gsub(/<\/?code>/, '')}</code>"
  end
  text.gsub!(/href="(.*?)"/) do
    "href=\"#{$1.gsub(/<\/?code>/, '')}\""
  end
  [name, text.gsub(/^#{indent}/, '')]
}]

rules = JSON.load(File.read('url.pegjson'))['rules']
rules.each do |rule|
  name = hyphenate(rule['name'])
  puts
  puts "## #{name} ## {##{name}}"

  puts
  puts "<pre class=railroad>"
  expression(rule['expression'], 0)
  puts "</pre>"

  if prose[rule['name']]
    puts 
    puts prose[rule['name']]
  end
end

puts
puts File.read('footer.in')
