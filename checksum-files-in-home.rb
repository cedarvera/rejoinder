#!/usr/bin/env ruby
# requires ruby 2.2

require "sequel"
require "find"
require "digest"

# DB = Sequel.sqlite("files.db")
DB = Sequel.connect("sqlite://files.db")

DB.create_table? :times do
  primary_key :time_key
  Datetime :time, :unique => true
end

DB.create_table? :paths do
  primary_key :path_key
  String :path, :unique => true
  String :name
end

DB.create_table? :sizes do
  primary_key :size_key
  Integer :size, :unique => true
end

DB.create_table? :statuses do
  primary_key :status_key
  foreign_key :mtime_key, :times # modification time
  foreign_key :atime_key, :times # access time
  foreign_key :ctime_key, :times # change time
  foreign_key :btime_key, :times # birth/creation time
end

DB.create_table? :files do
  primary_key :files_key
  foreign_key :path_key, :paths
  foreign_key :size_key, :sizes
  foreign_key :status_key, :statuses
  String      :md5
  String      :sha256
  foreign_key :scantime_key, :times
end

paths_tb = DB[:paths]
sizes_tb = DB[:sizes]
times_tb = DB[:times]
statuses_tb = DB[:statuses]
files_tb = DB[:files]

scantime = DateTime.now.to_time
if times_tb[:time => scantime] == nil then times_tb.insert(:time => scantime) end
scantime_key = DB[:times][:time => scantime][:time_key]
Find.find(ENV["HOME"]) do |path|
  if FileTest.file?(path)
    puts path
    # get the file data
    size = File.size(path)
    mtime = File.mtime(path)
    atime = File.atime(path)
    ctime = File.ctime(path)
    btime = File.birthtime(path)
    # add the data to tables if not there
    if paths_tb[:path => path]  == nil then paths_tb.insert(:path => path, :name => File.basename(path)) end
    if sizes_tb[:size => size]  == nil then sizes_tb.insert(:size => size) end
    if times_tb[:time => mtime] == nil then times_tb.insert(:time => mtime) end
    if times_tb[:time => atime] == nil then times_tb.insert(:time => atime) end
    if times_tb[:time => ctime] == nil then times_tb.insert(:time => ctime) end
    if times_tb[:time => btime] == nil then times_tb.insert(:time => btime) end
    # get the keys from the table
    mtime_key = times_tb[:time => mtime][:time_key]
    atime_key = times_tb[:time => atime][:time_key]
    ctime_key = times_tb[:time => ctime][:time_key]
    btime_key = times_tb[:time => btime][:time_key]
    # insert the status if the time key combination is not found
    if statuses_tb[:mtime_key => mtime_key, :atime_key => atime_key, :ctime_key => ctime_key, :btime_key => btime_key] == nil
      statuses_tb.insert(
        :mtime_key => mtime_key,
        :atime_key => atime_key,
        :ctime_key => ctime_key,
        :btime_key => btime_key
      )
    end
    # get the status key with the time key combination
    status_key = statuses_tb[
                   :mtime_key => mtime_key,
                   :atime_key => atime_key,
                   :ctime_key => ctime_key,
                   :btime_key => btime_key
                 ][:status_key]
    # insert the new file and stats
    files_tb.insert(
      :path_key => paths_tb[:path => path][:path_key],
      :size_key => sizes_tb[:size => size][:size_key],
      :status_key => status_key,
      :md5 => Digest::MD5.file(path).hexdigest,
      :sha256 => Digest::SHA256.file(path).hexdigest,
      :scantime_key => scantime_key
    )
  end
end
