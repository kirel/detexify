require 'logger'
require 'digest'
require 'erb'
require 'symbol'

module Latex

  module Storage

    L = Logger.new STDOUT

    TEMPLATE = ERB.new <<-LATEX.gsub(/^  /,'')
    \\documentclass[10pt]{article}
    \\usepackage[utf8]{inputenc} % Direkte Eingabe von Umlauten und anderen Diakritika

    <%= @packages %>

    \\pagestyle{empty}

    \\begin{document}

    <%= @command %>

    \\end{document}
    LATEX

    # INDEX = ERB.new <<-HTML.gsub(/^  /,'')
    # <html>
    # <body>
    #   <h1>Symbole</h1>
    #   <table>
    #     <% for s in @symbols %>
    #     <tr>
    #       <td><%= s.command %></td><td><img src='<%= s.id %>.png'></td>
    #     </tr>
    #     <% end %>
    #   </table>
    # </body>
    # </html>
    # HTML

    TMP = File.join(File.expand_path(File.dirname(__FILE__)),'tmp')
    OUT = File.join(File.expand_path(File.dirname(__FILE__)), 'public', 'images', 'symbols')

    module_function

    # return path of png file corresponding to symbol
    # creates png if necessary
    def png symbol
      file = File.join(OUT, filename(symbol))
      unless File.exists?(file+'.png')
        create symbol
      end
      file
    end

    # This needs a working LaTeX distribution and dvipng
    def create symbol
      prepare
      dvi = File.join(TMP, 'test.dvi')
      File.delete(dvi) if File.exist?(dvi)
      tempfile = File.new(File.join(TMP, 'test.tex'), 'w+')
      # setup variables
      @packages = ''
      @packages << "\\usepackage{#{symbol[:package]}}\n" if symbol[:package]
      @packages << "\\usepackage[#{symbol[:fontenc]}]{fontenc}\n" if symbol[:fontenc]
      @command = symbol.mathmode ? "$#{symbol.command}$" : symbol.command
      # write symbol to tempfile
      tempfile.puts TEMPLATE.result(binding)
      tempfile.close
      L.debug 'Generating latex...'
      system("latex -interaction=batchmode -output-directory=#{TMP} #{tempfile.path} >/dev/null")
      raise 'Panic! No dvi!' unless File.exist?(dvi)

      # Now convert to image
      file = File.join(OUT, filename(symbol))
      dpi = ENV['DPI'] || 600
      gamma = ENV['GAMMA'] || 1

      L.debug "Creating image... #{file}.png"
      # TODO check collisions
      system("dvipng -bg Transparent -T tight -v -D #{dpi} --gamma #{gamma} #{dvi} -o #{file}.png >/dev/null")

      File.delete(dvi)
    end
    
    def create_all
      Latex::Symbol::List.each do |symbol|
        create symbol
      end
    end

    # def index
    #   prepare
    #   L.debug 'Creating html index...'
    #   File.new(File.join(OUT, 'index.html'), 'w+') do |f|
    #     @symbols = Latex::Symbol::List
    #     f.puts INDEX.result(binding)        
    #   end
    # end

    private
    
    def self.filename symbol
      Digest::MD5.hexdigest symbol.id
    end

    def self.prepare
      Dir.mkdir TMP unless File.exist? TMP
      Dir.mkdir OUT unless File.exist? OUT
    end

    # TODO def clear -> wipe out tmp and out

  end

end
