require 'calculus/version'
require 'calculus/parser'
require 'calculus/latex'
require 'calculus/expression'

module Calculus
  # Raised when parser encounter invalid character
  class ParserError < Exception; end

  # Raised when <tt>Expression</tt> detects during calculation that
  # there are unbound variables presented
  class UnboundVariableError < Exception; end

  # Raised when <tt>LaTeX</tt> mixin detect missing binaries for images
  # rendering.
  class CommandNotFoundError < Exception; end
end
