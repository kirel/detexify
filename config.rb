# middleman config
configure :development do
  activate :livereload
end

set :css_dir, 'stylesheets'

set :js_dir, 'javascripts'

set :images_dir, 'images'

set :build_dir, 'public'

configure :build do
  activate :minify_css

  activate :minify_javascript

  activate :asset_hash

  activate :relative_assets

  # set :http_prefix, "/Content/images/"
end

# detexify stuff
$LOAD_PATH << ::File.join(::File.dirname(__FILE__), 'lib')
require 'detexify/latex_app'

map '/api' do
  run Detexify::LatexApp
end
