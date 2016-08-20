urls = Dir.glob('public/*').inject({}) do |h, path|
  h.update(path.sub('public', '') => path.sub('public/', ''))
end

use Rack::Static, urls: urls, index: 'index.html', root: 'public'

require './sample-tool'
run SampleTool
