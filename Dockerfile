FROM php:7-apache

MAINTAINER Tiago Pache <tiagopache@gmail.com>

LABEL Name=tiagopache/php7-apache-oci Version=1.0.0 

RUN apt-get update && \
    apt-get install -y libfreetype6-dev libxml2-dev libaio-dev unzip jq

# Oracle InstantClient
# Copy InstantClient Files
ADD oci/instantclient-basic-linux.x64-12.2.0.1.0.zip /tmp/
ADD oci/instantclient-sdk-linux.x64-12.2.0.1.0.zip /tmp/

# Decompress them
RUN unzip /tmp/instantclient-basic-linux.x64-12.2.0.1.0.zip -d /usr/local/ \
    && unzip /tmp/instantclient-sdk-linux.x64-12.2.0.1.0.zip -d /usr/local/

# Install OCI
RUN ln -s /usr/local/instantclient_12_2 /usr/local/instantclient \
    && ln -s /usr/local/instantclient/libclntsh.so.12.1 /usr/local/instantclient/libclntsh.so \
    && ln -s /usr/local/instantclient/libclntshcore.so.12.1 /usr/local/instantclient/libclntshcore.so \
    && ln -s /usr/local/instantclient/libocci.so.12.1 /usr/local/instantclient/libocci.so \
    && rm -rf /tmp/*.zip

# Install PHP required extensions
# -- GD
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ && \
    echo 'instantclient,/usr/local/instantclient' | pecl install oci8 && \
    docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/usr/local/instantclient,12.2 && \
    docker-php-ext-install -j$(nproc) gd \
        soap \
        pdo_oci && \
    docker-php-ext-enable \
        oci8 \
    && apt-get clean y && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -k -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Enable apache module rewrite
RUN cd /etc/apache2/mods-enabled && ln -s ../mods-available/rewrite.load