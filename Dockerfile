FROM realanmup/ubuntu18np:latest

# Update from server first
RUN apt-get update -yqq

# Installing basics
RUN apt install \
	curl \
	git \
	zip unzip \ 
	libpng-dev \
	nano \
	apt-utils -yqq && echo "Installing basics completed"

# Install php and required extensions
RUN DEBIAN_FRONTEND=noninteractive apt install -yqq \
        php7.2          php7.2-bcmath       php7.2-mbstring \
        php7.2-curl     php7.2-xml          php-zip \
        php-mysql       php-pgsql           php-fpm  \
	php-gd && echo "PHP installation complete"

# Setting up timezones
RUN echo $TIMEZONE > /etc/timezone && echo "date.timezone=$TIMEZONE" > /etc/php/7.2/cli/conf.d/timezone.ini

# Installing Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# Support for shell script in windows/mac
RUN apt install dos2unix

# Installing Node and package managers
RUN apt install nodejs npm -yqq && npm -g i n && npm -g i yarn && n 12

# Remove apache2 & install nginx
RUN apt-get purge apache2 -yqq && apt-get install nginx -yqq 

# Copy Nginx Default Config
COPY nginx.conf /etc/nginx/sites-enabled/default

COPY public/ /var/www/public/

# Forward request logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

RUN echo 'service php7.2-fpm start && /usr/sbin/nginx -g "daemon off;"' > /usr/bin/start_laradocker

CMD ["sh", "/usr/bin/start_laradocker"]

ARG USER_ID=1000
ARG GROUP_ID=1000

RUN userdel -f www-data &&\
    if getent group www-data ; then groupdel www-data; fi &&\
    groupadd -g ${GROUP_ID} www-data &&\
    useradd -l -u ${USER_ID} -g www-data www-data &&\
    install -d -m 0755 -o www-data -g www-data /home/www-data

WORKDIR /var/www/
