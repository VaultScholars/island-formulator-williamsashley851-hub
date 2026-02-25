# syntax = docker/dockerfile:1

FROM ruby:3.4.7-bookworm
ENV LANG C.UTF-8

ENV NODE_VERSION=22.21.1

ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid $USER_GID vscode \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash vscode

# Allow vscode user to write to Ruby system gems
RUN mkdir -p /usr/local/bundle \
    && chown -R vscode:vscode /usr/local/bundle \
    && find /usr/local/lib/ruby -type d -name gems -exec chown -R vscode:vscode {} \; 2>/dev/null || true

# # skip installing gem documentation with `gem install`/`gem update`
RUN set -eux; \
	mkdir -p /usr/local/etc; \
	echo 'gem: --no-document' >> /usr/local/etc/gemrc

# # Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
# Create /bundler directory with proper permissions for vscode user
RUN mkdir -p /bundler \
    && chown -R vscode:vscode /bundler \
    && chmod -R 755 /bundler

# Install Bundler 2.7.2 to match Gemfile.lock
RUN gem install bundler -v 2.7.2

# Install rake as a system gem (needed by herb gem during native extension build)
RUN gem install rake

RUN gem install rails -v 8.1.2

RUN gem install foreman

RUN apt update && apt install -y postgresql-common
RUN /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y

# Install packages needed to build gems and node modules
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl git \
    dpkg-dev libgdbm-dev \
    libpq-dev postgresql-client-16 libvips libvips-dev pkg-config openssh-client sqlite3 \
    tar gpg-agent gpg cmake lsof wget \
    poppler-utils libpoppler-glib-dev libgirepository1.0-dev ffmpeg

# Install Node.js
RUN ARCH=$(dpkg --print-architecture) && \
    NODE_ARCH=$(if [ "$ARCH" = "amd64" ]; then echo "x64"; else echo "$ARCH"; fi) && \
    curl -fsSLO --compressed "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" && \
    tar -xJf "node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -C /usr/local --strip-components=1 --no-same-owner && \
    rm "node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" && \
    ln -sf /usr/local/bin/node /usr/bin/node && \
    ln -sf /usr/local/bin/npm /usr/bin/npm && \
    npm install -g npm@latest

COPY .devcontainer/bashrc /root/.bashrc

SHELL ["/bin/bash", "-lc"]

# Install heroku cli
RUN curl https://cli-assets.heroku.com/install-ubuntu.sh | sh

WORKDIR /root
COPY .devcontainer/bashrc /root/.bashrc
COPY .devcontainer/bashrc /home/vscode/.bashrc
RUN chown vscode:vscode /home/vscode/.bashrc
