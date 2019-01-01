ARG PHP_VERSION=7.3.0
FROM php:${PHP_VERSION}-fpm-alpine

# build packages get deleted after
# the extension installation step
ARG BUILD_PACKAGES

# add permanent apk packages here
ARG PACKAGES

# if you need xdebug installed and
# configured, set to true
ARG INSTALL_XDEBUG=false

# extensions to be installed with
# docker-php-ext-* helpers
ARG EXTENSIONS

# pecl packages to be installed
ARG PECL_PACKAGES

# extension layer
RUN echo "BUILD: Install build packages." && \
    apk add --update --no-cache --virtual build-packages \
        # add build packages here
        ${PHPIZE_DEPS} git ${BUILD_PACKAGES} \
    && \
    echo "BUILD: Install required packages." && \
    apk add --update --no-cache \
        imagemagick-dev hiredis-dev ${PACKAGES} \
    && \
    echo "BUILD: install phpiredis" && \
    git clone https://github.com/nrk/phpiredis.git && \
    cd phpiredis && \
    phpize && ./configure --enable-phpiredis && \
    make && make install && \
    echo "BUILD: Update pecl channel." && \
    pecl channel-update pecl.php.net && \
    echo "BUILD: Extract php source." && \
    docker-php-source extract && \
    echo "BUILD: Install pecl packages." && \
    # @see https://pecl.php.net/package/imagick
    pecl install imagick-3.4.3 ${PECL_PACKAGES} && \
    docker-php-ext-enable imagick phpiredis \
        $(echo ${PECL_PACKAGES} | sed -E 's/-[0-9\.]+//g') && \
    if [ ${INSTALL_XDEBUG} = true ] ; then \
        # @see https://pecl.php.net/package/xdebug
        echo "BUILD: Install xdebug." && \
        pecl install xdebug-2.6.1 && \
        docker-php-ext-enable xdebug && \
        echo "xdebug.remote_port=9000" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
        echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
        echo "xdebug.remote_connect_back=on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    else \
        echo "BUILD: Skip install xdebug."; \
    fi && \
    echo "BUILD: Install core extensions." && \
    docker-php-ext-install pdo_mysql mysqli ${EXTENSIONS} && \
    echo "BUILD: Delet php source." && \
    docker-php-source delete && \
    echo "BUILD: Remove build packages." && \
    apk del build-packages
