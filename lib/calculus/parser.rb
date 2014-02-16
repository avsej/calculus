require 'strscan'

module Calculus

  # Parses string with expression or equation and builds postfix
  # notation. It supprorts following operators (ordered by precedence
  # from the highest to the lowest):
  #
  # +:sqrt+, +:exp+::   root and exponent operations. Could be written as
  #                     <tt>\sqrt[degree]{radix}</tt> and <tt>x^y</tt>.
  # +:div+, +:mul+::    division and multiplication. There are set of
  #                     syntaxes accepted. To make division operator you
  #                     can use <tt>num/denum</tt> or
  #                     <tt>\frac{num}{denum}</tt>. For multiplication
  #                     there accepted <tt>*</tt> and also two TeX
  #                     symbols: <tt>\cdot</tt> and <tt>\times</tt>.
  # +:plus+, +:minus+:: summation and substraction. Here you can use
  #                     plain <tt>+</tt> and <tt>-</tt>
  # +:eql+::            equals sign it has the lowest priority so it to
  #                     be calculated in last turn.
  #
  # Also it is possible to use parentheses for grouping. There are plain
  # <tt>(</tt>, <tt>)</tt> acceptable and also <tt>\(</tt>, <tt>\)</tt>
  # which are differ only for latex diplay. Parser doesn't distinguish
  # these two styles so you could give expression with visually
  # unbalanced parentheses (matter only for image generation. Consider
  # the example:
  #
  #   Parser.new("(2 + 3) * 4").parse   #=> [2, 3, :plus, 4, :mul]
  #   Parser.new("(2 + 3\) * 4").parse  #=> [2, 3, :plus, 4, :mul]
  #
  # This two examples will yield the same notation, but make issue
  # during display.
  #
  # Numbers could be given as a floats and as a integer
  #
  #   Parser.new("3 + 4.0 * 4.5e-10")   #=> [3, 4.0, 4.5e-10, :mul, :plus]
  #
  # Symbols could be just alpha-numeric values with optional subscript
  # index
  #
  #   Parser.new("x_3 + y * E")         #=> ["x_3", "y", "E", :mul, :plus]
  #
  class Parser < StringScanner
    attr_accessor :operators

    # Initialize parser with given source string. It could simple
    # (native expression like <tt>2 + 3 * (4 / 3)</tt>, but also in TeX
    # style <tt>2 + 3 \cdot \frac{4}{3}</tt>.
    def initialize(source)
      @operators = {:uminus => 4, :sqrt => 3, :exp => 3, :div => 2, :mul => 2, :plus => 1, :minus => 1, :eql => 0}

      super(source.dup)
    end

    # Run parse cycle. It builds postfix notation (aka reverse polish
    # notation). Returns array with operations with operands.
    #
    #   Parser.new("2 + 3 * 4").parse               #=> [2, 3, 4, :mul, :plus]
    #   Parser.new("(\frac{2}{3} + 3) * 4").parse   #=> [2, 3, :div, 3, :plus, 4, :mul]
    def parse
      exp = []
      stack = []
      token = :none
      while true
        prev, token = token, fetch_token
        case token
        when :open
          stack.push(token)
        when :close
          exp << stack.pop while operators.keys.include?(stack.last)
          stack.pop if stack.last == :open
        when :plus, :minus, :mul, :div, :exp, :sqrt, :eql
          token = :uminus if prev && (prev == :none || prev != :close) && token == :minus
          exp << stack.pop while operators.keys.include?(stack.last) && operators[stack.last] >= operators[token]
          stack.push(token)
        when Numeric, String
          exp << token
          token = nil
        when nil
          break
        else
          raise ArgumentError, "Unexpected symbol: #{token.inspect}"
        end
      end
      exp << stack.pop while stack.last && stack.last != :open
      raise ArgumentError, "Missing closing parentheses: #{stack.join(', ')}" unless stack.empty?
      exp
    end

    # Fetch next token from source string. Skips any whitespaces
    # matching regexp <tt>/\s+/</tt> and returs <tt>nil</tt> at when
    # meet the end of string.
    #
    # Raises <tt>ParseError</tt> when encounter invalid character
    # sequence.
    def fetch_token
      skip(/\s+/)
      return nil if(eos?)

      token = nil
      scanning = true
      while(scanning)
        scanning = false
        token = case
                when scan(/=/)
                  :eql
                when scan(/\*|\\times|\\cdot/)
                  :mul
                when scan(/\\frac\s*(?<num>\{(?:(?>[^{}])|\g<num>)*\})\s*(?<denom>\{(?:(?>[^{}])|\g<denom>)*\})/)
                  num, denom = [self[1], self[2]].map{|v| v.gsub(/^{|}$/, '')}
                  string[pos, 0] = "(#{num}) / (#{denom}) "
                  scanning = true
                when scan(/\//)
                  :div
                when scan(/\+/)
                  :plus
                when scan(/\^/)
                  :exp
                when scan(/-/)
                  :minus
                when scan(/sqrt/)
                  :sqrt
                when scan(/\\sqrt\s*(?<deg>\[(?:(?>[^\[\]])|\g<deg>)*\])?\s*(?<rad>\{(?:(?>[^{}])|\g<rad>)*\})/)
                  deg = (self[1] || "2").gsub(/^\[|\]$/, '')
                  rad = self[2].gsub(/^{|}$/, '')
                  string[pos, 0] = "(#{rad}) sqrt (#{deg}) "
                  scanning = true
                when scan(/\(|\\left\(/)
                  :open
                when scan(/\)|\\right\)/)
                  :close
                when scan(/[\-\+]? [0-9]+ ((e[\-\+]?[0-9]+)| (\.[0-9]+(e[\-\+]?[0-9]+)?))/x)
                  matched.to_f
                when scan(/[\-\+]?[0-9]+/)
                  matched.to_i
                when scan(/([a-z0-9]+(?>_[a-z0-9]+)?)/i)
                  matched
                else
                  raise ParserError, "Invalid character at position #{pos} near '#{peek(20)}'."
                end
      end

      return token
    end

  end
end
