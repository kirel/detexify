require 'rake/tasklib'
require 'erb'
require 'latex/symbol'

class SymbolTask < Rake::TaskLib

  TEMPLATE = ERB.new <<-LATEX #open('template.tex.erb').read
    \\documentclass[10pt]{article}
    \\usepackage[utf8]{inputenc}

    <%= @packages %>

    \\pagestyle{empty}
    \\begin{document}

    <%= @command %>

    \\end{document}
  LATEX

  TMP = 'tmp'
  OUT = 'images/latex'

  attr_accessor :name, :tmp, :out

  # initialize sets the name and calls a block to get
  #   the rest of the options
  def initialize(name = :generate)
      @name = name
      yield self if block_given?
      define
  end

  # define creates the new task(s)
  def define
    # desc "prepare necessary directories"
    # task :prepare do
      directory TMP
      directory OUT
    # end

    all_image_tasks = Latex::Symbol::List.map do |symbol|
      define_single_tex_task symbol
      define_single_dvi_task symbol
      define_single_image_task symbol
    end

    namespace :symbols do
      desc "create sprite"
      task :sprite => :resize do
        require 'sprite_factory'
        SpriteFactory.cssurl = "image-url('$IMAGE')"    # use a sass-rails helper method to be evaluated by the rails asset pipeline
        SpriteFactory.run!('images/latex', style: 'sass', pngcrush: true, layout: 'packed',
                           output_style: 'source/stylesheets/symbols.sass',
                           output_image: 'source/images/symbols.png')
        SpriteFactory.cssurl = "url('$IMAGE')"    # use a sass-rails helper method to be evaluated by the rails asset pipeline
        SpriteFactory.run!('images/latex', style: 'css', pngcrush: true,
                           output_style: 'sample-tool/public/symbols.css',
                           output_image: 'sample-tool/public/symbols.png')
      end

      task :resize => @name do
        system 'mogrify -path images/latex -thumbnail "60x40>" images/latex/*.png'
      end

      desc "create png images from all symbols"
      task @name => all_image_tasks

      desc "create json"
      task :json do
        FileUtils.mkdir_p 'json'
        File.open("json/symbols.json", "w+") do |json|
          json.write Latex::Symbol::List.to_json
        end
        FileUtils.cp('json/symbols.json', 'sample-tool/public/symbols.json')
      end
    end # namespace
  end


  def define_single_image_task symbol
    file "#{File.join(OUT, symbol.filename)}.png" => [OUT, "#{File.join(TMP, symbol.filename)}.dvi"] do |t|
      # Now convert to image
      dpi = ENV['DPI'] || 600
      gamma = ENV['GAMMA'] || 1

      puts "Creating image... #{t.name}"
      sh %|dvipng -bg Transparent -T tight -v -D #{dpi} --gamma #{gamma} #{File.join(TMP, symbol.filename)}.dvi -o #{t.name} >/dev/null| do |ok, res|
        if ! ok
          puts "Major Failure creating image! (status = #{res.exitstatus})"
        end
      end

    end
    "#{File.join(OUT, symbol.filename)}.png" # need the names
  end

  def define_single_dvi_task symbol
    file "#{File.join(TMP, symbol.filename)}.dvi" => [TMP, "#{File.join(TMP, symbol.filename)}.tex"] do
      puts "Generating dvi for #{symbol}..."
      sh %|latex -interaction=batchmode -output-directory=#{TMP} #{File.join(TMP, symbol.filename)}.tex >/dev/null| do |ok, res|
        if ! ok
          puts "Major Failure creating dvi! (status = #{res.exitstatus})"
        end
      end
    end
  end

  def define_single_tex_task symbol
    file "#{File.join(TMP, symbol.filename)}.tex" => TMP do |t|
      open(t.name, 'w+') do |texfile|
        # setup variables
        @packages = ''
        @packages << "\\usepackage{#{symbol[:package]}}\n" if symbol[:package]
        @packages << "\\usepackage[#{symbol[:fontenc]}]{fontenc}\n" if symbol[:fontenc]
        @command = symbol.mathmode ? "$#{symbol.command}$" : symbol.command
        # write symbol to tempfile
        puts "Generating latex for #{symbol}..."
        texfile.puts TEMPLATE.result(binding)
      end
    end
  end

end
