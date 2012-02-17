require 'pathname'

class Pathname

  alias :'/' :'+'

  def =~(o); @path =~ o; end

  def subpath?(other)
    self.to_s =~ /^#{Regexp.escape other.to_s}#{Regexp.quote File::SEPARATOR}/i
  end

  # Recursively find all files which match a specified regular
  # expression.
  def find_all_files(re)
    Dir.glob(File.join(self.to_s, '**/*')).select do |x|
      File.basename(x) =~ re
    end.map do |x|
      Pathname.new(x)
    end
  end

  def Pathname.pwd
    Pathname.new(Dir.pwd)
  end

  def Pathname.pathequal(a, b)
    a.downcase == b.downcase
  end

  def ext(new_ext = nil)
    if new_ext
      Pathname.new(@path.sub(/(\.[^.]*?)?$/) { new_ext })
    else
      File.extname(@path)
    end
  end

  def ext?(expected_ext)
    Pathname.pathequal(ext, expected_ext)
  end

  def to_native
    if Ocra.windows?
      return @path.tr File::SEPARATOR, File::ALT_SEPARATOR
    end
    to_posix
  end
    
  def to_posix
    if Ocra.windows?
      return @path.tr File::ALT_SEPARATOR, File::SEPARATOR
    end
    to_path
  end

end

class Object
  def to_pathname
    case self
    when Pathname
      self
    when Array
      self.map { |x| Pathname(x) }
    when String
      Pathname.new(self)
    when NilClass
      nil
    else
      raise ArgumentError, self
    end
  end
end
