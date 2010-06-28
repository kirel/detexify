require 'init'

use Rack::Static, :urls => ["/favicon.ico", "/classify.html", "/symbols.html", "/css", "/images", "/flash", "/js"], :root => "public"

map '/' do
  run Detexify::LatexApp
end
