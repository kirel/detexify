# Sample tool

    $ docker build -t sample-tool .
    $ docker run -it --rm --link detexify3_postgres_1:db -e PORT=9292 -p 9292:9292 sample-tool

and open http://localhost:9292

    $ docker tag sample-tool registry.heroku.com/sample-tool/web
    $ docker push registry.heroku.com/sample-tool/web
