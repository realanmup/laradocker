FROM ubuntu:20.10


ARG USER_ID=1000
ARG GROUP_ID=1000

# Update from server first
RUN apt-get update -yqq

# Installing basics
RUN apt install \
	curl \
	git \
	zip unzip \ 
	libpng-dev \
	nano \
  cron \
  dos2unix \
	apt-utils -yqq && echo "Installing basics completed"

# Install php and required extensions
RUN DEBIAN_FRONTEND=noninteractive apt install -yqq \
        php          php-bcmath       php-mbstring \
        php-curl     php-xml          php-zip \
        php-mysql    php-pgsql        php-fpm  \
	php-redis      php-gd    php-curl && echo "PHP installation complete"

# Installing Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# Installing Node and package managers
ENV NVM_DIR /usr/local
ENV NODE_VERSION 14


# Remove apache2 & install nginx nodejs npm
RUN apt-get purge apache2 -yqq && apt-get install nginx nodejs npm -yqq 

RUN npm i -g n && n 14

# To Run Cron Job
COPY cron cron

RUN crontab cron && cron

# Copy Nginx Default Config
COPY nginx.conf /etc/nginx/sites-enabled/default

COPY public/ /var/www/public/

# Forward request logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log
  
EXPOSE 80

STOPSIGNAL SIGTERM

RUN echo 'service php7.4-fpm start && /usr/sbin/nginx -g "daemon off;"' > /usr/bin/start_laradocker

RUN userdel -f www-data &&\
    if getent group www-data ; then groupdel www-data; fi &&\
    groupadd -g ${GROUP_ID} www-data &&\
    useradd -l -u ${USER_ID} -g www-data www-data &&\
    install -d -m 0755 -o www-data -g www-data /home/www-data

WORKDIR /var/www/

CMD ["sh", "/usr/bin/start_laradocker"]
