ARG IMAGE_VERSION=2

FROM ubuntu:22.04

ENV TZ=UTC
ENV NODE_MAJOR=16
ENV PHP_VERSION=8.2

# Remove interaction while installing or upgrading via apt and select a default timezone
RUN DEBIAN_FRONTEND=noninteractive
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# See https://ubuntu.com/blog/we-reduced-our-docker-images-by-60-with-no-install-recommends
RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker
RUN echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker

RUN apt-get update
RUN apt-get install -y \
    autoconf \
    autogen \
    language-pack-en-base \
    wget \
    zip \
    unzip \
    curl \
    rsync \
    ssh \
    openssh-client \
    git \
    build-essential \
    apt-utils \
    software-properties-common \
    nasm \
    libjpeg-dev \
    libpng-dev \
    libpng16-16 \
    gpg-agent \
    ca-certificates \
    gnupg

# PHP
RUN add-apt-repository ppa:ondrej/php && apt-get update && apt-get install -y php$PHP_VERSION
RUN apt-get install -y \
    php$PHP_VERSION-curl \
    php$PHP_VERSION-gd \
    php$PHP_VERSION-dev \
    php$PHP_VERSION-xml \
    php$PHP_VERSION-bcmath \
    php$PHP_VERSION-mysql \
    php$PHP_VERSION-pgsql \
    php$PHP_VERSION-mbstring \
    php$PHP_VERSION-zip \
    php$PHP_VERSION-bz2 \
    php$PHP_VERSION-sqlite \
    php$PHP_VERSION-soap \
    php$PHP_VERSION-intl \
    php$PHP_VERSION-imap \
    php$PHP_VERSION-imagick \
    php-memcached
RUN command -v php

# Composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer && \
    composer self-update
RUN command -v composer

# Allow php havier tasks as scoper and rector
RUN sed -i 's/memory_limit = .*/memory_limit = 2G/' /etc/php/$PHP_VERSION/cli/php.ini
RUN sed -i 's/max_execution_time = .*/max_execution_time = 0/' /etc/php/$PHP_VERSION/cli/php.ini

# WP CLI
# This is a build container used only locally and in GitHub Actions.
# Root access in WP-CLI is not a concern in our context.
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp-cli.phar
RUN echo '#!/bin/sh' >> /usr/local/bin/wp
RUN echo 'wp-cli.phar $@ --allow-root' >> /usr/local/bin/wp
RUN chmod +x /usr/local/bin/wp
RUN command -v wp

# Node.js
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update && apt-get install nodejs
RUN npm install yarn -g
RUN npm install gulp-cli -g
RUN command -v node
RUN command -v yarn
RUN command -v gulp

# Other
RUN mkdir ~/.ssh
RUN touch ~/.ssh_config

# Display versions installed
RUN php -v
RUN composer --version
RUN node -v
RUN npm -v
RUN yarn -v
RUN gulp -v

# Entrypoint
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /app

# Add a separete volume to allow mounting the project files from the host
# This is useful to keep the container performance on IO operations
RUN mkdir -p /app-volume

WORKDIR /app

ENTRYPOINT ["/entrypoint.sh"]