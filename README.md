# localmark (MIRROR)

LocalMark provides an easy way to create source code annotations, allowing users to download, store, and annotate various types of content from different sources.

# usage

~~~
$ docker run -d --restart=always -ti -p 5000:5000 -v <DIRECTORY LOCALMARKS>:/localmark_storage --name localmark
bit4bit/localmark
~~~

then [OPEN](http://localhost:5000)

# Examples

see [examples](/examples)


# testing

## Run all tests
carton exec prove -l t/

## Run BDD tests only
carton exec prove -l t/run_bdd.t

## Run integration tests (with real network)
CI_REAL_TESTS=1 carton exec prove -l t/integration/smoke.t

# Contributing

please see [CONTRIBUTING](chiselapp.com/user/bit4bit/repository/localmark/)
