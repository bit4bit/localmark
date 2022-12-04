FROM perl:5.36.0
LABEL org.opencontainers.image.authors="Jovany Leandro G. C <bit4bit@riseup.net>"

RUN apt-get update && apt-get install -y wget2 highlight plantuml git fossil mercurial youtube-dl

COPY . /usr/src/app

WORKDIR /usr/src/app

RUN cpanm --installdeps --notest .
RUN cpanm install Starman

ENV DANCER_PORT=5000
VOLUME ["/localmark_storage"]

COPY docker.prod.env /usr/src/app/prod.env

CMD plackup -s Starman -I./lib script/localmark.pl
