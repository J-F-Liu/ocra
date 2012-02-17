require 'ocra/version'

module Ocra
  def self.platform
    # if windows, require ocra pathname
    if RUBY_PLATFORM =~ /(win|w)32$/
      return :windows
    end
    return :linux
  end
end

require "ocra/#{Ocra.platform}/pathname"
# pathname extensions
require 'ocra/ext/pathname'

require 'ocra/host'
require "ocra/#{Ocra.platform}/library_detector"
require "ocra/#{Ocra.platform}/builder"

module Ocra
  def self.Pathname(obj)
    obj.to_pathname
  end
end