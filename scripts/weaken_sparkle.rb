#!/usr/bin/env ruby
# frozen_string_literal: true

LC_LOAD_DYLIB = 0x0000000C
LC_LOAD_WEAK_DYLIB = 0x80000018
SPARKLE_DYLIB_NAME = "@rpath/Sparkle.framework/Versions/B/Sparkle"

binary_path = ARGV[0]

unless binary_path && File.exist?(binary_path)
  warn "Usage: ruby weaken_sparkle.rb /path/to/binary"
  exit 1
end

data = File.binread(binary_path)
str_offset = data.index(SPARKLE_DYLIB_NAME)

unless str_offset
  warn "No Sparkle dylib reference found in binary; nothing to patch."
  exit 0
end

patched = false
(24..256).each do |offset|
  cmd_start = str_offset - offset
  next if cmd_start < 0

  cmd = data[cmd_start, 4].unpack1("V")
  next unless cmd == LC_LOAD_DYLIB

  name_offset = data[cmd_start + 8, 4].unpack1("V")
  next unless name_offset == offset

  data[cmd_start, 4] = [LC_LOAD_WEAK_DYLIB].pack("V")
  patched = true
  break
end

unless patched
  warn "Found Sparkle string but no strong LC_LOAD_DYLIB command to patch; continuing."
  exit 0
end

File.binwrite(binary_path, data)
warn "Patched Sparkle load command: LC_LOAD_DYLIB -> LC_LOAD_WEAK_DYLIB"
