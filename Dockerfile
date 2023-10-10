FROM ubuntu:22.04

# CONF
ARG USER_ID=1000
ARG GROUP_ID=1000
ENV NODE_VERSION 16

# Basic Packages
RUN apt-get update -yq && apt install \
  software-properties-common \
	curl    git     zip     unzip   libpng-dev \
  nano    supervisor      dos2unix    nginx rsync \
  nodejs  npm    apt-utils     imagemagick  -yqq && echo "Installing basics completed"

RUN add-apt-repository ppa:ondrej/php

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris

# Install php and required extensions
RUN apt-get update -yq && apt install -yqq \
        php8.2-fpm libapache2-mod-fcgid \
        tzdata          php8.2              php8.2-bcmath   \
        php8.2-mbstring \
        php8.2-curl     php8.2-xml          php8.2-zip \
        php8.2-mysql    php8.2-pgsql        php8.2-fpm  \
        php8.2-imagick  php8.2-redis        php8.2-gd \
        php8.2-intl \
        php8.2-curl php8.2-gmp php8.2-mongodb php8.2-sqlite3 && echo "PHP installation complete"

# Remove apache2 & install nginx nodejs npm
RUN apt-get purge apache2 -yqq && apt autoremove -yqq

# Installing Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# Upgrading NodeJS
RUN npm i -g n && n $NODE_VERSION

# Copy Nginx Configs
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default /etc/nginx/sites-enabled/default

COPY public/ /var/www/public/

# Forward request logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log
  
# script: start_laradocker
RUN echo 'service php8.2-fpm start && /usr/sbin/nginx -g "daemon off;"' > /usr/bin/start_laradocker && chmod +x /usr/bin/start_laradocker

# Set www-data user to host
RUN userdel -f www-data &&\
    if getent group www-data ; then groupdel www-data; fi &&\
    groupadd -g ${GROUP_ID} www-data &&\
    useradd -l -u ${USER_ID} -g www-data www-data &&\
    install -d -m 0755 -o www-data -g www-data /home/www-data

WORKDIR /var/www/

STOPSIGNAL SIGTERM

EXPOSE 80

CMD ["sh", "/usr/bin/start_laradocker"]
