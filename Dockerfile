FROM resin/raspberrypi3-debian

RUN apt-get update && apt-get install -y curl wget build-essential ruby-dev ruby openssl bsdtar
RUN gem install fpm
COPY ./ /usr/src/app/

ENV TRG_RESIN_OS="2.9.6+rev1.prod"
ENV PLATFORM="raspberrypi3"
ENV KERNEL="4.9.59"
ENV PACKAGE_VERSION="1.0.0"
ENV ARCH=armhf
WORKDIR /usr/src/app
ENTRYPOINT [ "/usr/bin/entry.sh", "/usr/src/app/entrypoint.sh" ]
CMD ["--help"]
