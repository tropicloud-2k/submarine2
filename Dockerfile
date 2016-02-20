FROM alpine:edge
MAINTAINER admin@tropicloud.net

ADD . /wps
RUN /wps/bin/build.sh

ENV WP_ENV=development \
    WP_REPO=https://github.com/roots/bedrock.git

EXPOSE 80 443
WORKDIR /submarine
ENTRYPOINT ["wps"]
