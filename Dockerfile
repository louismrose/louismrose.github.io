FROM ruby:2.6-buster

WORKDIR /site

RUN sed -i \
      -e 's|deb.debian.org/debian|archive.debian.org/debian|g' \
      -e 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' \
      /etc/apt/sources.list \
    && sed -i '/buster-updates/d' /etc/apt/sources.list \
    && apt-get -o Acquire::Check-Valid-Until=false update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN gem install bundler -v 2.4.22

COPY Gemfile ./
COPY Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 4000

CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--baseurl", "/"]
