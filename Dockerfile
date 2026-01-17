FROM ruby:2.7-alpine

COPY Gemfile Gemfile.lock* ./

RUN apk update && \
    apk add --no-cache build-base linux-headers zlib-dev libxml2-dev libxslt-dev && \
    bundle install && \
    apk del build-base linux-headers && \
    rm -rf /usr/lib/ruby/gems/*/cache/* \
           /var/cache/apk/* \
           /tmp/* \
           /var/tmp/*

WORKDIR /usr/src/app
EXPOSE 8000
CMD bundle exec jekyll serve --port 8000 --host 0.0.0.0 --drafts 
