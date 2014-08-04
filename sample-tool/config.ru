urls = Dir.glob('public/*').inject({}) do |h, path|
  h.update(path.sub('public', '') => path.sub('public/', ''))
end

use Rack::Static, urls: urls, index: 'index.html', root: 'public'

require 'rack/reverse_proxy'
require 'uri'

uri = URI.parse ENV['COUCH']

use Rack::ReverseProxy do
  reverse_proxy_options :preserve_host => true
  reverse_proxy '/', (ENV['COUCH'] or abort "Set couch!"),
    username: uri.user,
    password: uri.password
end

app = proc do |env|
  [ 200, {'Content-Type' => 'text/plain'}, "Why are we here?" ]
end

run app
