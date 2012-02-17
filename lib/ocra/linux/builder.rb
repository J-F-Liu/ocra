module Ocra
  class Builder

    def initialize(path, windowed)
      File.open(path, "w") do |f|
      end

      yield(self)

    end

    def method_missing(name, *args)
      puts "#{name.upcase} #{args.join(', ')}"
    end

  end
end