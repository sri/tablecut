#! /usr/bin/env ruby
require 'set'

# Simple HTML utilities.
class String
  def strip_html
    self.gsub(/<[^>]*>/, '')
  end
  
  def scan_tags(tag)
    self.scan(/<#{tag}[^>]*>(.*?)<\/#{tag}>/im).flatten
  end
end

# Print the headers and rows nicely.
def pp_table(headers, rows)
  if headers.empty? || rows.empty?
    return
  end
  puts headers.map { |h| "%20s" % h.upcase }.join
  rows.map { |cols| puts cols.map { |c| "%20s" % c }.join }
  #puts "=" * 80
end

def tablecut(html)
  # 1. We gather all the starting & ending points of the tables.
  starting = []
  ending = []
  html.scan(/<\s*table/im) { |m| starting << Regexp.last_match }
  html.scan(/<\/\s*table\s*>/im) { |m| ending << Regexp.last_match }
  
  tmap = []
  seen = Set.new
  
  # 2. Match the ending to the closest starting that
  # appears before it, that hasn't been seen before.
  # This works because all elements of ENDING are in 
  # the order that they were found in the HTML.
  ending.each do |e|
    sp = e.offset(0).first
    diff = -1
    elt = nil
    
    starting.each do |s|
      next if seen.include?(s)      
      tdiff = sp - s.offset(0).first
      if tdiff < 0
        next
      elsif diff == -1 || tdiff < diff
        diff = tdiff
        elt = s
      end
    end
    
    tmap << [elt, e]
    seen.add elt
  end
  
  # 3. Get rid of tables that have nesting.
  non_nested = []
  nested = []
  
  tmap.each do |s, e|
    is_nested = nil
    tmap.each do |s2, e2|
      next if (s == s2 && e == e2)
      if s.offset(0).first < s2.offset(0).first &&
         e.offset(0).last > e2.offset(0).last
         is_nested = true
         break
       end
    end
    
    if is_nested
      nested << [s, e]
    else
      non_nested << [s, e]
    end
    
  end
  
  # 4. For each non-nested table: generate the
  # substring that contains the table and extract
  # rows & columns
  non_nested.each do |s, e|
    a = s.offset(0).first
    b = e.offset(0).last
    table = html[a..b]
    
    hd, *rows = table.scan_tags("tr")
    headers = hd.scan_tags("td").map { |x| x.strip_html }
    if headers.empty?
      headers = hd.scan_tags("th").map { |x| x.strip_html }
    end
    rows = rows.map { |r| r.scan_tags("td").map { |c| c.strip_html } }
    
    pp_table headers, rows
    
  end
end

if __FILE__ == $0
  require 'open-uri'
  url = ARGV[0] || abort("Usage: tablecut URL")
  tablecut open(url).read
end
