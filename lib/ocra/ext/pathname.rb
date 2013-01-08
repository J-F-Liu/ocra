class Object
  def to_pathname
    case self
    when Ocra::Pathname
      self
    when Array
      self.map { |x| Ocra::Pathname(x) }
    when String
      Ocra::Pathname.new(self)
    when NilClass
      nil
    else
      raise ArgumentError, self
    end
  end
end