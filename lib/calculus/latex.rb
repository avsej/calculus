require 'tmpdir'

module Calculus

  module Latex

    TEMPLATE = <<-EOT.gsub(/^\s+/, '')
      \\documentclass{article}
      \\usepackage{amsmath,amssymb}
      \\begin{document}
      \\thispagestyle{empty}
      $$ # $$
      \\end{document}
    EOT

    def to_png(density = 700)
      raise CommandNotFoundError, "Required commands missing: #{missing_commands.join(', ')} in PATH. (#{ENV['PATH']})" unless missing_commands.empty?

      temp_path = Dir.mktmpdir
      Dir.chdir(temp_path) do
        File.open("#{sha1}.tex", 'w') do |f|
          f.write(TEMPLATE.sub('#', self.to_s))
        end
        `latex -interaction=nonstopmode #{sha1}.tex && dvipng -q -T tight -bg White -D #{density.to_i} -o #{sha1}.png #{sha1}.dvi`
      end
      return File.join(temp_path, "#{sha1}.png") if $?.exitstatus.zero?
    ensure
      File.unlink("#{sha1}.tex") if File.exists?("#{sha1}.tex")
      File.unlink("#{sha1}.dvi") if File.exists?("#{sha1}.dvi")
    end

    def missing_commands
      commands = []
      commands << "latex" unless can_run?("latex -v")
      commands << "dvipng" unless can_run?("dvipng -v")
      commands
    end

    protected

    def can_run?(command)
      `#{command} 2>&1`
      $?.exitstatus.zero?
    end
  end

end
