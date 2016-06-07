#!/usr/bin/env ruby

require "pathname"
require "fileutils"
require "nokogiri"
require "json"
require "uri"

# extract the dictionary data
def extract_dict(dict)
  hash = {}
  key = nil
  dict.children.each do |item|
    if item.element?
      case item.name
        when "key"          then key = item.content
        when "string"       then hash[key] = URI.unescape(item.content)
        when "date", "data" then hash[key] = item.content
        when "integer"      then hash[key] = Integer(item.content)
        when "true"         then hash[key] = true
        when "false"        then hash[key] = false
        when "array"        then hash[key] = extract_array(item)
        when "dict"         then hash[key] = extract_dict(item)
        else
          puts item.name
      end
    end
  end
  return hash
end

# extract the array data
def extract_array(array)
  arr = []
  array.children.each do |item|
    if item.element?
      case item.name
        when "string"       then arr.push(URI.unescape(item.content))
        when "date", "data" then arr.push(item.content)
        when "integer"      then arr.push(Integer(item.content))
        when "true"         then arr.push(true)
        when "false"        then arr.push(false)
        when "array"        then arr.push(extract_array(item))
        when "dict"         then arr.push(extract_dict(item))
        else
          puts item.name
      end
    end
  end
  return arr
end

contents = []
ARGV.each do |path|
  file = File.open(path, "r")
  doc = Nokogiri::XML(file)
  contents.push(extract_dict(doc.xpath("/plist/dict")))
  #puts JSON.pretty_generate extract_dict(doc.xpath("/plist/dict")) #.to_json
  file.close()
end

contents.each do |content|
  content["Tracks"].each do |key, value|
    path = value["Location"].sub("file://", "")
    if not File.exists?(path) \
       and (not path.include?("/Podcasts/") or value.has_key?("Podcast") and not value["Podcast"]) \
       and not path.include?("/Voice Memos/")
    #if not path.include?("/Podcasts/") and not path.include?("/Voice Memos/")
      puts "#{value["Artist"]} - #{value["Name"]}, #{value["Play Count"]}"
      #FileUtils.touch(File.join(".", "music", File.basename(path)))
      #FileUtils.touch(path)
    end
  end
end
