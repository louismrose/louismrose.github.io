ARG RUBY_VERSION
FROM ruby:${RUBY_VERSION}

WORKDIR /site

COPY .ruby-version Gemfile Gemfile.lock ./
RUN NOKOGIRI_USE_SYSTEM_LIBRARIES=true bundle install

COPY . .

EXPOSE 4000

CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--baseurl", "/"]
