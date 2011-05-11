# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "calculus/version"

Gem::Specification.new do |s|
  s.name        = "calculus"
  s.version     = Calculus::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Sergey Avseyev"]
  s.email       = ["sergey.avseyev@gmail.com"]
  s.homepage    = "http://avsej.net/calculus"
  s.summary     = %q{A ruby parser for TeX equations}
  s.description = %q{A ruby parser for TeX equations. It parses equations to postfix (reverse polish) notation and can build abstract syntax tree (AST). Also it can render images via latex.}

  s.rubyforge_project = "calculus"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
