require 'calculus/version'
require 'calculus/parser'
require 'calculus/latex'
require 'calculus/expression'

module Calculus
  class ParserError < Exception; end
  class UnboundVariableError < Exception; end
  class CommandNotFoundError < Exception; end
end
