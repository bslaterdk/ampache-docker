FROM composer:1.10.8 AS Builder

ADD https://github.com/ampache/ampache/archive/develop.tar.gz /tmp
RUN     tar -xzf /tmp/develop.tar.gz --strip=1 -C . \
    &&  rm -rf .git* .php_cs .sc .scrutinizer.yml .tgitconfig .travis.yml .tx *.md \
    &&  mv ./rest/.htac* ./rest/.htaccess \
    &&  mv ./play/.htac* ./play/.htaccess \
    &&  mv ./channel/.htac* ./channel/.htaccess \
    &&  chmod -R 775 ./


FROM debian:stable
LABEL maintainer="lachlan-00"

ENV DEBIAN_FRONTEND=noninteractive
ENV MYSQL_PASS **Random**

RUN     apt-get -q -q update \
    &&  apt-get -q -q -y install --no-install-recommends \
          software-properties-common
RUN     apt-add-repository contrib \
    &&  apt-add-repository non-free
RUN     apt-get -q -q update \
    &&  apt-get -q -q -y install --no-install-recommends libdvd-pkg
RUN     dpkg-reconfigure libdvd-pkg
RUN     apt-get update \
    &&  apt-get -qq install --no-install-recommends \
          apache2 \
          cron \
          composer \
          ffmpeg \
          flac \
          git \
          gosu \
          inotify-tools \
          lame \
          libavcodec-extra \
          libev-libevent-dev \
          libfaac-dev \
          libmp3lame-dev \
          libtheora-dev \
          libvorbis-dev \
          libvpx-dev \
          mariadb-server \
          php \
          php-curl \
          php-gd \
          php-intl \
          php-json \
          php-mysql \
          php-xml \
          pwgen \
          supervisor \
          vorbis-tools \
          zip
RUN     apt-get -qq purge \
          libdvd-pkg \
          lsb-release \
          python3 \
          python3-minimal \
          software-properties-common
RUN     rm -rf /var/lib/mysql/* /var/www/* /etc/apache2/sites-enabled/* /var/lib/apt/lists/* \
    &&  mkdir -p /var/run/mysqld \
    &&  chown -R mysql /var/run/mysqld \
    &&  ln -s /etc/apache2/sites-available/001-ampache.conf /etc/apache2/sites-enabled/ \
    &&  a2enmod rewrite \
    &&  rm -rf /var/cache/* /tmp/* /var/tmp/* /root/.cache \
    &&  echo '30 7 * * *   /usr/bin/php /var/www/bin/catalog_update.inc' | crontab -u www-data -

COPY --from=Builder --chown=www-data:www-data /app /var/www

RUN     su -s /bin/sh -c 'cd /var/www && composer install --prefer-source --no-interaction' www-data
RUN     apt-get -qq purge git composer

VOLUME ["/etc/mysql", "/var/lib/mysql", "/media", "/var/www/config", "/var/www/themes"]
EXPOSE 80

COPY run.sh inotifywatch.sh cron.sh apache2.sh mysql.sh create_mysql_admin_user.sh /usr/local/bin/
COPY 001-ampache.conf /etc/apache2/sites-available/
COPY --chown=www-data:www-data ampache.cfg.* /var/temp/
COPY docker-entrypoint.sh /usr/local/bin
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["run.sh"]
