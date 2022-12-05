FROM perl:5.36.0
LABEL org.opencontainers.image.authors="Jovany Leandro G. C <bit4bit@riseup.net>"

RUN apt-get update && apt-get install -y wget2 highlight plantuml git fossil mercurial ffmpeg python3 python3-pip python3-dev

COPY . /usr/src/app

WORKDIR /usr/src/app

RUN cpanm --installdeps --notest .
RUN cpanm install -n -f Starman

# otras dependencias
RUN pip install --upgrade youtube-dl
RUN curl https://dist.ipfs.tech/ipget/v0.9.1/ipget_v0.9.1_linux-amd64.tar.gz -o /tmp/ipget.tar.gz
RUN cd /tmp/ && tar -xf ipget.tar.gz && cp ipget/ipget /usr/bin && chmod a+rx /usr/bin/ipget

ENV DANCER_PORT=5000
VOLUME ["/localmark_storage"]

COPY docker.prod.env /usr/src/app/prod.env

CMD plackup -s Starman  -I./lib script/localmark.pl
