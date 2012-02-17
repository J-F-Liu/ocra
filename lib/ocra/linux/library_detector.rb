
module Ocra

  module LibraryDetector

    def LibraryDetector.loaded_dlls
      dlls = []
      File.open("/proc/#{Process.pid}/maps") do |f|
        f.each_line do |line|
          pieces = line.split(" ")
          dll = pieces.last
          dlls << Pathname.new(dll) if dll =~ /\.so/
        end
      end
      dlls.uniq
    end

    def LibraryDetector.detect_dlls
      #loaded = loaded_dlls
      #exec_prefix = Host.exec_prefix
      #loaded.select { |path| path.subpath?(exec_prefix) && path.basename.ext?('.dll') && path.basename != Host.libruby_so }
      loaded_dlls
    end
  end

end