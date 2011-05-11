require 'calculus/version'
require 'calculus/parser'
require 'calculus/expression'

module Calculus
  class ParserError < Exception; end
  class UnboundVariableError < Exception; end
end
