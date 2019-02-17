FROM php:7.3-apache

RUN apt-get -qq update && \
    apt-get install -qy libxml2-dev && \
    pecl install apcu && \
    docker-php-ext-enable apcu && \
    docker-php-source extract && \
    docker-php-ext-install -j$(nproc) soap && \
    docker-php-source delete && \
    a2enmod dav dav_fs dav_lock rewrite
