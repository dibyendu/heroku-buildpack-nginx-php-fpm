#!/bin/bash

source ./set-env.sh

set -e
set -o pipefail

orig_dir=$( pwd )

mkdir -p build && pushd build

# install libmcrypt
echo "+ Fetching libmcrypt libraries..."
mkdir -p /app/local
curl -L https://s3.amazonaws.com/$S3_BUCKET/libmcrypt-heroku-bin.tar.gz -o - | tar xz -C /app/local

#fetch php, extract
echo "+ Fetching PHP sources..."
curl -L http://us.php.net/get/php-$PHP_VERSION.tar.gz/from/www.php.net/mirror -o - | tar xz

pushd php-$PHP_VERSION

## configure command
## WARNING: libmcrypt needs to be installed.
echo "+ Configuring PHP..."
./configure \
--prefix=/app/vendor/php \
--with-config-file-path=/app/vendor/php \
--with-config-file-scan-dir=/app/vendor/php/etc.d \
--disable-debug \
--disable-rpath \
--enable-cgi \
--enable-fpm \
--enable-gd-native-ttf \
--enable-inline-optimization \
--enable-libxml \
--enable-mbregex \
--enable-mbstring \
--enable-pcntl \
--enable-soap=shared \
--enable-zip \
--with-bz2 \
--with-curl \
--with-gd \
--with-gettext \
--with-jpeg-dir \
--with-mcrypt=/app/local \
--with-iconv \
--with-mhash \
--with-openssl \
--with-pcre-regex \
--with-png-dir \
--with-zlib

# build & install it
echo "+ Compiling PHP..."
make && make install

popd

# update path
export PATH=/app/vendor/php/bin:$PATH

# configure pear
pear config-set php_dir /app/vendor/php

# install apc from source
echo "+ Installing APC..."
curl -L http://pecl.php.net/get/APC-${APC_VERSION}.tgz -o - | tar xz


pushd APC-${APC_VERSION}
phpize
./configure --enable-apc --enable-apc-filehits --with-php-config=/app/vendor/php/bin/php-config
make && make install
popd

# install php-mongo-driver from source
echo "+ Installing Mongodb Driver..."
curl -L https://github.com/mongodb/mongo-php-driver/archive/${MONGO_VERSION}.tar.gz -o - | tar xz

pushd mongo-php-driver-${MONGO_VERSION}
phpize
./configure --with-php-config=/app/vendor/php/bin/php-config
make && make install
popd

# package PHP
echo "+ Packaging PHP..."
echo ${PHP_VERSION} > /app/vendor/php/VERSION

popd

echo "+ Done!"
