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
	php-ext         php-gd \
    && echo "PHP installation complete"

# Setting up timezones
RUN echo $TIMEZONE > /etc/timezone && echo "date.timezone=$TIMEZONE" > /etc/php/7.2/cli/conf.d/timezone.ini

# Installing Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# Support for shell script in windows/mac
RUN apt install dos2unix

# Installing Node and package managers
RUN apt install nodejs npm -yqq && npm -g i yarn

# Remove apache2 & install nginx
RUN apt-get purge apache2 -yqq && apt-get install nginx -yqq && service nginx start && service php7.2-fpm start

# Host on port 80
EXPOSE 80
