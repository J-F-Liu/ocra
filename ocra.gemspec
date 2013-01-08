# -*- encoding: utf-8 -*-
require File.expand_path("../lib/ocra/version", __FILE__)

Gem::Specification.new do |s|
  s.name = "ocra"
  s.version = Ocra::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lars Christensen", "Duncan Mac-Vicar P.", "Junfeng Liu"]
  s.date = "2013-01-08"
  s.description = "OCRA (One-Click Ruby Application) builds Windows executables from Ruby\r\nsource code. The executable is a self-extracting, self-running\r\nexecutable that contains the Ruby interpreter, your source code and\r\nany additionally needed ruby libraries or DLL."
  s.email = "larsch@belunktum.dk"
  s.executables = ["ocra"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc"]
  s.files = `git ls-files`.split("\n")
  s.homepage = "http://ocra.rubyforge.org/"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "ocra"
  s.rubygems_version = "1.8.23"
  s.summary = "OCRA (One-Click Ruby Application) builds Windows executables from Ruby\r source code"
end
