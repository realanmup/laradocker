FROM --platform=linux/amd64 ubuntu:24.04

# CONF
ARG USER_ID=1000
ARG GROUP_ID=1000
ENV NODE_VERSION 20
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kathmandu
ARG PHP_VERSION=8.3
ENV PHP_VERSION=${PHP_VERSION}

# Basic Packages + PHP + Extensions + Nginx + NodeJS + Composer
RUN apt-get update -yq && \
    apt-get install -yqq software-properties-common curl git zip unzip libpng-dev nano supervisor nginx rsync nodejs npm apt-utils imagemagick ghostscript ffmpeg && \
    echo "Installing basics completed" && \
    add-apt-repository ppa:ondrej/php && \
    apt-get update -yq && \
    apt-get install -yqq php${PHP_VERSION}-fpm libapache2-mod-fcgid tzdata php${PHP_VERSION} php${PHP_VERSION}-bcmath php${PHP_VERSION}-mbstring php${PHP_VERSION}-curl php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-mysql php${PHP_VERSION}-pgsql php${PHP_VERSION}-fpm php${PHP_VERSION}-imagick php${PHP_VERSION}-redis php${PHP_VERSION}-gd php${PHP_VERSION}-intl php${PHP_VERSION}-gmp php${PHP_VERSION}-mongodb php${PHP_VERSION}-sqlite3 php${PHP_VERSION}-exif && \
    echo "PHP installation complete" && \
    apt-get purge apache2 -yqq && apt autoremove -yqq && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer && \
    npm i -g n && n $NODE_VERSION  && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Enable PDF support in ImageMagick
RUN sed -i 's/<policy domain="coder" rights="none" pattern="PDF" \/>/<policy domain="coder" rights="read|write" pattern="PDF" \/>/' /etc/ImageMagick-6/policy.xml && \
    sed -i 's/<policy domain="coder" rights="none" pattern="PS" \/>/<policy domain="coder" rights="read|write" pattern="PS" \/>/' /etc/ImageMagick-6/policy.xml && \
    sed -i 's/<policy domain="coder" rights="none" pattern="EPS" \/>/<policy domain="coder" rights="read|write" pattern="EPS" \/>/' /etc/ImageMagick-6/policy.xml && \
    apt-get install -yq php${PHP_VERSION}-dompdf

# Configure Nginx
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default /etc/nginx/sites-enabled/default

# Configure PHP
COPY php/php.ini /etc/php/${PHP_VERSION}/fpm/php.ini 
COPY php/php-fpm.conf /etc/php/${PHP_VERSION}/fpm/php-fpm.conf
COPY php/www.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# Configure default index.php
COPY public/index.php /var/www/public/index.php

# Configure boot loader
COPY scripts/start_laradocker /usr/bin/start_laradocker
RUN chmod +x /usr/bin/start_laradocker

# Set www-data user to host
RUN userdel -f www-data && \
    if getent group www-data ; then groupdel www-data; fi && \
    groupadd -g ${GROUP_ID} www-data && \
    useradd -l -u ${USER_ID} -g www-data www-data && \
    install -d -m 0755 -o www-data -g www-data /home/www-data

WORKDIR /var/www/

STOPSIGNAL SIGTERM

EXPOSE 80 443 9000

ENV PHP_FPM_BACKEND="unix:/run/php/php${PHP_VERSION}-fpm.sock"

CMD ["sh", "/usr/bin/start_laradocker"]