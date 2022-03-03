FROM perl:5.34.0

WORKDIR /usr/src/app

COPY cpanfile /usr/src/app
RUN cpanm --installdeps .
