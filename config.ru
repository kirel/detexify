require './init'

use Rack::Static, :urls => ["/favicon.ico", "/classify.html", "/symbols.html", "/stylesheets", "/images", "/flash", "/javascripts", "/fonts"], :root => "public"

map '/api' do
  run Detexify::LatexApp
end

map '/' do
  run Detexify::LatexApp
end
