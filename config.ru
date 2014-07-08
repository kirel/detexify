require './init'

use Rack::Static, :urls => ["/favicon.ico", "/index.html", "/symbols.html", "/stylesheets", "/images", "/flash", "/javascripts"], :root => "public"

map '/api' do
  run Detexify::LatexApp
end
