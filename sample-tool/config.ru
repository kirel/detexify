urls = Dir.glob('public/*').inject({}) do |h, path|
  h.update(path.sub('public', '') => path.sub('public/', ''))
end

require 'rack/contrib'
use Rack::Static, urls: urls, index: 'index.html', root: 'public'
use Rack::PostBodyContentTypeParser

require './sample-tool'
run SampleTool
