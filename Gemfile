source 'https://rubygems.org'

ruby '2.1.2'

gem "json"
gem "sinatra"
gem "rest-client", :require => 'rest_client'
gem "httparty"
gem "armchair"
gem "couchrest"
gem "threadify"
gem "thin" # for deployment on heroku

group :test do
  gem "rspec"
  gem "fakeweb"
  gem "rack-test"
end

group :development do
  gem 'dotenv'
end

group :rake do
  gem "rake"
  gem "aws-s3"
end
