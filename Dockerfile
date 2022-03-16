FROM perl:5.34.0

RUN apt-get update && apt-get install wget2 highlight plantuml git fossil mercurial

COPY . /usr/src/app

WORKDIR /usr/src/app

RUN cpanm --installdeps .
