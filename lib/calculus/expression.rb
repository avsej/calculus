require 'digest/sha1'

module Calculus

  # This class represent some expression and optionaly transform it to
  # the postfix notation for later analysis.
  #
  # Expression can introduce variables which could be substituted later
  #
  #   exp = Expression.new("x + 2 * 4")
  #   exp.to_s                            #=> "x + 2 * 4"
  #   exp.calculate                       # raises UnboundVariableError
  #   exp["x"] = 5
  #   exp.to_s                            #=> "5 + 2 * 4"
  #   exp.calculate                       #=> 40
  #
  class Expression
    include Latex

    # Represents unique identifier of expression. Should be changed when
    # some variables are binding
    attr_reader :sha1

    # Source expression string
    attr_reader :source

    # Array with postfix notation of expression
    attr_reader :postfix_notation
    alias :rpn :postfix_notation

    # Initialize instance with given string expression.
    #
    # It is possible to skip parser.
    #
    #   # raises Calculus::ParserError: Invalid character...
    #   x = Expression.new("\sum_{i=1}^n \omega_i \x_i")
    #   # just stores source string and allows rendering to PNG
    #   x = Expression.new("\sum_{i=1}^n \omega_i \x_i", :parse => false)
    #   x.parsed?   #=> false
    #
    # It raises ArgumentError if there are more than one equal sign
    # because if you need to represent the system of equations you
    # should you two instances of <tt>Expression</tt> class and no
    # equals sign for just calculation.
    #
    # Also it initializes SHA1 fingerprint of particular expression
    def initialize(source, options = {})
      options = {:parse => true}.merge(options)
      @source = source
      @postfix_notation = options[:parse] ? Parser.new(source).parse : []
      raise ArgumentError, "Should be no more that one equals sign" if @postfix_notation.count(:eql) > 1
      @variables = extract_variables
      update_sha1
    end

    # Returns <tt>true</tt> when postfix notation has been built
    def parsed?
      !@postfix_notation.empty?
    end

    # Returns <tt>true</tt> if there equals sign presented
    def equation?
      @postfix_notation.include?(:eql)
    end

    # Returns array of strings with variable names
    def variables
      @variables.keys
    end

    # Returns array of variables which have nil value
    def unbound_variables
      @variables.keys.select{|k| @variables[k].nil?}
    end

    # Getter for given variable.
    # Raises an <tt>Argument</tt> exception when there no such variable.
    def [](name)
      raise ArgumentError, "No such variable defined: #{name}" unless @variables.keys.include?(name)
      @variables[name]
    end

    # Setter for given variable.
    # Raises an <tt>Argument</tt> exception when there no such variable.
    def []=(name, value)
      raise ArgumentError, "No such variable defined: #{name}" unless @variables.keys.include?(name)
      @variables[name] = value
      update_sha1
    end

    # Perform traverse along postfix notation. Yields <tt>operation</tt>
    # with <tt>left</tt> and <tt>right</tt> operands and the latest
    # argument is the current state of <tt>stack</tt> (*note* you can
    # amend this stack from outside)
    def traverse(&block) # :yields: operation, left, right, stack
      stack = []
      @postfix_notation.each do |node|
        case node
        when Symbol
          operation, right, left = node, (node == :uminus ? nil : stack.pop), stack.pop
          stack.push(yield(operation, left, right, stack))
        when Numeric
          stack.push(node)
        when String
          stack.push(@variables[node] || node)
        end
      end
      stack.pop
    end

    # Traverse postfix notation and calculate the actual value of
    # expression. Raises <tt>NotImplementedError</tt> when equation
    # detected (currently it cannot solve equation) and
    # <tt>UnboundVariableError</tt> if there unbound variables found.
    #
    # *Note* that there some rounding errors here in root operation
    # because of general approach to calculate it:
    #
    #   1000 ** (1.0 / 3)   #=>   9.999999999999998
    #
    def calculate
      raise NotImplementedError, "Equation detected. This class can't calculate equations yet." if equation?
      raise UnboundVariableError, "Can't calculate. Unbound variables found: #{unbound_variables.join(', ')}" unless unbound_variables.empty?

      traverse do |operation, left, right, stack|
        case operation
        when :uminus then -left
        when :sqrt   then left ** (1.0 / right) # could cause some rounding errors
        when :exp    then left ** right
        when :plus   then left + right
        when :minus  then left - right
        when :mul    then left * right
        when :div    then left / right
        end
      end
    end

    # Builds abstract syntax tree (AST) as alternative expression
    # notation. Return nested array where first member is an operation
    # and the other operands
    #
    #   Calculus::Expression.new("x + 2 * 4").ast   #=> [:plus, "x", [:mul, 2, 4]]
    #
    def abstract_syntax_tree
      traverse do |operation, left, right, stack|
        [operation, left, right]
      end
    end
    alias :ast :abstract_syntax_tree

    # Returns string representation of expression. Substitutes bound
    # variables.
    def to_s
      result = source.dup
      (variables - unbound_variables).each do |var|
        result.gsub!(/(\W)#{var}(\W)/, "\\1#{@variables[var]}\\2")
        result.gsub!(/^#{var}(\W)/, "#{@variables[var]}\\1")
        result.gsub!(/(\W)#{var}$/, "\\1#{@variables[var]}")
        result.gsub!(/^#{var}$/, @variables[var].to_s)
      end
      result
    end

    def inspect # :nodoc:
      "#<Expression:#{@sha1} postfix_notation=#{@postfix_notation.inspect} variables=#{@variables.inspect}>"
    end

    protected

    # Extracts variables from postfix notation and returns <tt>Hash</tt>
    # object with keys corresponding to variables and nil initial
    # values.
    def extract_variables
      @postfix_notation.select{|node| node.kind_of? String}.inject({}){|h, v| h[v] = nil; h}
    end

    # Update SHA1 fingerprint. Used during initialization and when
    # variables is bounding.
    def update_sha1
      @sha1 = Digest::SHA1.hexdigest([@postfix_notation, @variables].map(&:inspect).join('-'))
    end

  end

end
