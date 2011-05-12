require 'strscan'

module Calculus

  class Parser < StringScanner
    attr_accessor :operators

    def initialize(source)
      @operators = {:sqrt => 3, :exp => 3, :div => 2, :mul => 2, :plus => 1, :minus => 1, :eql => 0}

      super(source.dup)
    end

    def parse
      exp = []
      stack = []
      while true
        case token = fetch_token
        when :open
          stack.push(token)
        when :close
          exp << stack.pop while operators.keys.include?(stack.last)
          stack.pop if stack.last == :open
        when :plus, :minus, :mul, :div, :exp, :sqrt, :eql
          exp << stack.pop while operators.keys.include?(stack.last) && operators[stack.last] >= operators[token]
          stack.push(token)
        when Numeric, String
          exp << token
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
