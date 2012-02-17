module Ocra

  # Path handling class. Ruby's Pathname class is not used because it
  # is case sensitive and doesn't handle paths with mixed path
  # separators.
  class Pathname

    SEPARATOR_PAT = /[#{Regexp.quote File::ALT_SEPARATOR}#{Regexp.quote File::SEPARATOR}]/ # }
    ABSOLUTE_PAT = /\A([A-Z]:)?#{SEPARATOR_PAT}/i
    
    def initialize(path)
      @path = path
    end
    
    def to_path
      @path
    end

    def to_native
      @path.tr File::SEPARATOR, File::ALT_SEPARATOR
    end
    
    def to_posix
      @path.tr File::ALT_SEPARATOR, File::SEPARATOR
    end

    # Compute the relative path from the 'src' path (directory) to 'tgt'
    # (directory or file). Return the absolute path to 'tgt' if it can't
    # be reached from 'src'.
    def relative_path_from(other)
      a = @path.split(SEPARATOR_PAT)
      b = other.path.split(SEPARATOR_PAT)
      while a.first && b.first && Pathname.pathequal(a.first, b.first)
        a.shift
        b.shift
      end
      return other if Pathname.new(b.first).absolute?
      b.size.times { a.unshift '..' }
      return Pathname.new(a.join('/'))
    end

    # Determines if 'src' is contained in 'tgt' (i.e. it is a subpath of
    # 'tgt'). Both must be absolute paths and not contain '..'
    def subpath?(other)
      other = Ocra.Pathname(other)
      src_normalized = to_posix.downcase
      tgt_normalized = other.to_posix.downcase
      src_normalized =~ /^#{Regexp.escape tgt_normalized}#{SEPARATOR_PAT}/i
    end

    # Join two pathnames together. Returns the right-hand side if it
    # is an absolute path. Otherwise, returns the full path of the
    # left + right.
    def +(other)
      other = Ocra.Pathname(other)
      if other.absolute?
        other
      else
        Ocra.Pathname(@path + '/' + other.path)
      end
    end
    
    def append_to_filename!(s)
      @path.sub!(/(\.[^.]*?|)$/) { s.to_s + $1 }
    end

    def entries
      Dir.entries(@path).map { |e| self / e }
    end


    def ==(other); to_posix.downcase == other.to_posix.downcase; end
    def <=>(other); @path.casecmp(other.path); end
    def exist?; File.exist?(@path); end
    def file?; File.file?(@path); end
    def directory?; File.directory?(@path); end
    def absolute?; @path =~ ABSOLUTE_PAT; end
    def dirname; Pathname.new(File.dirname(@path)); end
    def basename; Pathname.new(File.basename(@path)); end
    def expand_path(dir = nil); Pathname.new(File.expand_path(@path, dir && Ocra.Pathname(dir))); end
    def size; File.size(@path); end

    alias to_s to_posix
    alias to_str to_posix
  end
end