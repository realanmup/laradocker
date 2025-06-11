FROM --platform=linux/amd64 ubuntu:24.04

# CONF
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG NODE_VERSION=20
ENV NODE_VERSION=${NODE_VERSION}
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kathmandu
ARG PHP_VERSION=8.3
ENV PHP_VERSION=${PHP_VERSION}

# Basic Packages + PHP + Extensions + Nginx + NodeJS + Composer
RUN apt-get update -yqq && \
    apt-get install -yqq software-properties-common curl git zip unzip libpng-dev nano supervisor nginx rsync nodejs npm apt-utils imagemagick ghostscript ffmpeg && \
    echo "Installing basics completed" 

RUN add-apt-repository ppa:ondrej/nginx && \
    apt-get update -yqq && \
    apt-get install -yqq php${PHP_VERSION}-fpm libapache2-mod-fcgid tzdata php${PHP_VERSION} php${PHP_VERSION}-bcmath php${PHP_VERSION}-mbstring php${PHP_VERSION}-curl php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-mysql php${PHP_VERSION}-pgsql php${PHP_VERSION}-fpm php${PHP_VERSION}-imagick php${PHP_VERSION}-redis php${PHP_VERSION}-gd php${PHP_VERSION}-intl php${PHP_VERSION}-gmp php${PHP_VERSION}-mongodb php${PHP_VERSION}-sqlite3 php${PHP_VERSION}-common && \
    echo "PHP installation complete" && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer && \
    npm i -g n && n $NODE_VERSION  && \
    echo "Nodejs $NODE_VERSION installed" && \
    apt-get purge apache2 -yqq && apt autoremove -yqq && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Enable PDF support in ImageMagick
RUN sed -i 's/<policy domain="coder" rights="none" pattern="PDF" \/>/<policy domain="coder" rights="read|write" pattern="PDF" \/>/' /etc/ImageMagick-6/policy.xml && \
    sed -i 's/<policy domain="coder" rights="none" pattern="PS" \/>/<policy domain="coder" rights="read|write" pattern="PS" \/>/' /etc/ImageMagick-6/policy.xml && \
    sed -i 's/<policy domain="coder" rights="none" pattern="EPS" \/>/<policy domain="coder" rights="read|write" pattern="EPS" \/>/' /etc/ImageMagick-6/policy.xml

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

WORKDIR /var/www/

STOPSIGNAL SIGTERM

EXPOSE 80 443 9000

ENV PHP_FPM_BACKEND="unix:/run/php/php${PHP_VERSION}-fpm.sock"

CMD ["sh", "/usr/bin/start_laradocker"]