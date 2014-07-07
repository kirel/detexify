# Detexify (Frontend)

LaTeX symbol classifier as a webservice. This is the frontend. Uses https://github.com/kirel/detexify-hs-backend as the backend.

## Setup

- Install Ruby 2.1.2 and Bundler
- `$ bundle`
- `$ bundle exec dotenv rackup`
- open http://localhost:9292

This runs the frontend locally using the production backend. It is configured via [environment variables](.env). To setup the backend locally see https://github.com/kirel/detexify-hs-backend

## Tests

Check if all symbols are compiling: `$ rspec spec`

## Tasks

reminder for myself `source ~/.aws`

### Adding symbols

_You need Latex installed!_

Symbols are configured in [lib/latex/symbols.yml](lib/latex/symbols.yml).

1. Add the symbol
2. run the tests `$ rspec spec`
3. Create a Pull-Request

For me:

4. generate the symbol images `$ rake symbols:generate`
5. upload them `$ rake symbols:upload`
6. Redeploy `git push heroku master`

### Populate the backend

`$ bundle exec dotenv rake populate` (uses `TRAINCOUCH` to populate `CLASSIFIER` - see [.env](.env) for defaults)

## License

Copyright (c) 2009 Daniel Kirsch, released under the MIT license, see MIT-LICENSE