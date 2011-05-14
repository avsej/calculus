require 'tmpdir'

module Calculus

  # Renders expression to PNG image using <tt>latex</tt> and
  # <tt>dvipng</tt>
  module Latex

    # Basic latex template which use packages <tt>amsmath</tt> and
    # <tt>amssymb</tt> from standard distributive and set off expression
    # with <tt>$$</tt>.
    TEMPLATE = <<-EOT.gsub(/^\s+/, '')
      \\documentclass{article}
      \\usepackage{amsmath,amssymb}
      \\begin{document}
      \\thispagestyle{empty}
      $$ # $$
      \\end{document}
    EOT

    # Render image from source expression string. It is possible to pass
    # <tt>background</tt> color (default: <tt>'White'</tt>) and
    # <tt>density</tt> (default: <tt>700</tt>). See <tt>dvipng(1)</tt>
    # page for details.
    #
    # Raises <tt>CommandNotFound</tt> exception when some tools not
    # available.
    #
    # Returns path to images. *Note* that caller should take care about
    # this file.
    def to_png(background = 'White', density = 700)
      raise CommandNotFoundError, "Required commands missing: #{missing_commands.join(', ')} in PATH. (#{ENV['PATH']})" unless missing_commands.empty?

      temp_path = Dir.mktmpdir
      Dir.chdir(temp_path) do
        File.open("#{sha1}.tex", 'w') do |f|
          f.write(TEMPLATE.sub('#', self.to_s))
        end
        `latex -interaction=nonstopmode #{sha1}.tex && dvipng -q -T tight -bg #{background} -D #{density.to_i} -o #{sha1}.png #{sha1}.dvi`
      end
      return File.join(temp_path, "#{sha1}.png") if $?.exitstatus.zero?
    ensure
      File.unlink("#{sha1}.tex") if File.exists?("#{sha1}.tex")
      File.unlink("#{sha1}.dvi") if File.exists?("#{sha1}.dvi")
    end

    # Check LaTeX toolchain availability and returns array of missing
    # tools
    def missing_commands
      commands = []
      commands << "latex" unless can_run?("latex -v")
      commands << "dvipng" unless can_run?("dvipng -v")
      commands
    end

    protected

    # Trial command and check if return code is zero
    def can_run?(command)
      `#{command} 2>&1`
      $?.exitstatus.zero?
    end
  end

end
