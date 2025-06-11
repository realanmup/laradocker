FROM ubuntu:20.04

# CONF
ARG USER_ID=1000
ARG GROUP_ID=1000
ENV NODE_VERSION 16

RUN apt-get update -yqq && apt-get install software-properties-common -yqq
RUN add-apt-repository ppa:ondrej/php && add-apt-repository ppa:nginx/stable

# Basic Packages
RUN apt-get update -yqq && apt install \
	curl    git     zip     unzip   libpng-dev \
  nano    supervisor      dos2unix    nginx \
  jpegoptim optipng pngquant gifsicle \
  rsync openssh-client \
  nodejs  npm    apt-utils     imagemagick  -yqq && echo "Installing basics completed"

# Install php and required extensions
RUN DEBIAN_FRONTEND=noninteractive apt install -yqq \
        php8.1          php8.1-bcmath       php8.1-mbstring \
        php8.1-curl     php8.1-xml          php8.1-zip \
        php8.1-mysql    php8.1-pgsql        php8.1-fpm  \
        php8.1-imagick  php8.1-redis        php8.1-gd \
        php8.1-curl     php8.1-mongodb php8.1-imagick && echo "PHP installation complete"

# Remove apache2 & install nginx nodejs npm
RUN apt-get purge apache2 -yqq && apt autoremove -yqq

# Installing Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# Upgrading NodeJS
RUN npm i -g n svgo && n $NODE_VERSION

# Copy Nginx Configs
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default /etc/nginx/sites-enabled/default

COPY public/ /var/www/public/

# Forward request logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log
  
# script: start_laradocker
RUN echo 'service php8.1-fpm start && /usr/sbin/nginx -g "daemon off;"' > /usr/bin/start_laradocker && chmod +x /usr/bin/start_laradocker

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
