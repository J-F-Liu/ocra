#!/usr/bin/env ruby
# -*- ruby -*-

$lzma_mode = true
$extra_dlls = []
$files = []

usage = <<EOF
ocra [--dll dllname] [--no-lzma] script.rb

--dll dllname    Include additional DLLs from the Ruby bindir.
--no-lzma        Disable LZMA compression of the executable.
--quiet          Suppress output.
--help           Display this information.
EOF

while arg = ARGV.shift
  case arg
  when /\A--(no-)?lzma\z/
    $lzma_mode = !$1
  when /\A--dll\z/
    $extra_dlls << ARGV.shift
  when /\A--quiet\z/
    $quiet = true
  when /\A--help\z/, /\A--/
    puts usage
    exit
  else
    $files << arg
  end
end

if $files.empty?
  puts usage
  exit
end

if defined? Gem
  puts "=== Warning: Rubygems is loaded. Rubygems will be included the archive."
  puts "        RUBYOPT=#{ENV['RUBYOPT']}"
end

puts "=== Loading script to check dependencies" unless $quiet
load $files[0]
libs = $LOADED_FEATURES.map { |scr|
  sp = $:.find { |path| File.file?(File.join(path, scr)) }
  [scr, sp]
}

if defined?(DATA)
  $sebimage = DATA.read(DATA.readline.to_i).unpack("m")[0]
  $lzmaimage = DATA.read(DATA.readline.to_i).unpack("m")[0]
  $lzmapath = File.join(ENV['TEMP'], 'lzma.exe').tr('/','\\')
  puts $lzmapath
  puts $lzmaimage.size
  File.open($lzmapath, "wb") { |f| f << $lzmaimage }
else
  $sebimage = File.open(File.join(File.dirname(__FILE__), '../share/ocra/stub.exe'), "rb") { |f| f.read }
  $lzmapath = File.join(File.dirname(__FILE__), '../share/ocra/lzma.exe')
  raise "lzma.exe not found" unless File.exist?($lzmapath)
end
# $sebimage = File.open("seb.exe", "rb") { |f| f.read }

require 'rbconfig'
bindir = RbConfig::CONFIG['bindir']
libruby_so = RbConfig::CONFIG['LIBRUBY_SO']

Signature = [0x41, 0xb6, 0xba, 0x4e]
OP_END = 0
OP_CREATE_DIRECTORY = 1
OP_CREATE_FILE = 2
OP_CREATE_PROCESS = 3
OP_DECOMPRESS_LZMA = 4

class SebBuilder
  def initialize(path)
    @paths = {}
    File.open(path, "wb") do |f|
      f.write($sebimage)
      if $lzma_mode
        @of = ""
      else
        @of = f
      end
      yield(self)

      if $lzma_mode
        File.open("tmpin", "wb") { |tmp| tmp.write(@of) }
        system("#{$lzmapath} e tmpin tmpout 2>NUL") or fail
        @c = File.open("tmpout", "rb") { |tmp| tmp.read }
        f.write([OP_DECOMPRESS_LZMA, @c.size, @c].pack("VVA*"))
        f.write([OP_END].pack("V"))
      else
        f.write(@of) if $lzma_mode
      end

      f.write([OP_END].pack("V"))
      f.write([$sebimage.size].pack("V"))
      f.write(Signature.pack("C*"))
    end
  end
  def mkdir(path)
    @paths[path] = true
    puts "m #{path}" unless $quiet
    @of << [OP_CREATE_DIRECTORY, path].pack("VZ*")
  end
  def ensuremkdir(tgt)
    return if tgt == "."
    if not @paths[tgt]
      ensuremkdir(File.dirname(tgt))
      mkdir(tgt)
    end
  end
  def createfile(src, tgt)
    ensuremkdir(File.dirname(tgt))
    str = File.open(src, "rb") { |s| s.read }
    puts "a #{tgt}" unless $quiet
    @of << [OP_CREATE_FILE, tgt, str.size, str].pack("VZ*VA*")
  end
  def createprocess(image, cmdline)
    @of << [OP_CREATE_PROCESS, image, cmdline].pack("VZ*Z*")
  end
  def close
    @of.close
  end
end


executable = $files[0].sub(/(\.rb)?$/, '.exe')

puts "=== Building #{executable}" unless $quiet
SebBuilder.new(executable) do |sb|
  sb.mkdir('src')
  sb.createfile($files[0], 'src\\' + $files[0])
  sb.mkdir('bin')
  sb.createfile(File.join(bindir, "ruby.exe"), "bin\\ruby.exe")
  sb.createfile(File.join(bindir, libruby_so), "bin\\msvcrt-ruby18.dll")
  $extra_dlls.each { |dll|
    sb.createfile(File.join(bindir, dll), File.join("bin", dll).tr('/','\\'))
  }

  libs.each { |path, tgt|
    jn = File.join(tgt, path)
    if jn =~ /\/(lib\/ruby\/.*)$/
      dst = $1
    else
      dst = tgt
    end
    dst.tr!('/', '\\')
    sb.createfile(jn, dst)
  }
  
  sb.createprocess("bin\\ruby.exe", "ruby.exe \xff\\src\\" + $files[0])
end
puts "=== Finished (Final size was #{File.size(executable)})" unless $quiet