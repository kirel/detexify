# Sample tool

    $ export COUCH=`heroku config --app detexify4 | grep COUCH | awk '{print $2}'`
    $ rackup

and open http://localhost:9292
