FROM ubuntu:18.04

LABEL maintainer="deivisjl"

RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ENV LANG en_US.utf8
ENV DEBIAN_FRONTEND=noninteractive

# Use bash instead of sh.
SHELL ["/bin/bash", "-c"]

#Install Apache2
RUN apt-get update \
    && apt-get -y install apache2

#Install php
RUN apt-get -y install software-properties-common \
    && add-apt-repository ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y curl supervisor zip php-mbstring unzip libpng-dev ca-certificates \
    && apt-get install -y php7.3 libapache2-mod-php7.3 php7.3-cli php7.3-mysql php7.3-pgsql php7.3-gd \
    && apt-get install -y php7.3-imagick php7.3-recode php7.3-tidy php7.3-xmlrpc php7.3-mbstring \
    && apt-get install -y php7.3-xml php7.3-zip php7.3-cgi php7.1-mcrypt \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*   

#App
COPY . /var/www/html/

#Supervisord
COPY docker/apache/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/apache/supervisord/start-apache-supervisor /usr/local/bin/start-apache-supervisor
RUN chmod +x /usr/local/bin/start-apache-supervisor

#Virtual Host
COPY docker/apache/000-default.conf /etc/apache2/sites-available/000-default.conf

#Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#Install dependencies
WORKDIR /var/www/html
RUN composer install --ignore-platform-reqs  --optimize-autoloader --no-dev

#Optimize framework
RUN php artisan optimize:clear

#Permissions
RUN chown -R www-data:www-data /var/www/html
RUN chmod -R 775 /var/www/html/storage
RUN a2enmod rewrite

EXPOSE 80

ENTRYPOINT ["start-apache-supervisor"]
