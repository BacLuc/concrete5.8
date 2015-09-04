FROM chriswayg/apache-php
MAINTAINER Christian Wagner chriswayg@gmail.com

# This image provides Concrete5.7 at root of site
# - latest download link at https://www.concrete5.org/get-started
# - for newer version: change Concrete5 version# & download url & md5
ENV CONCRETE5_VERSION 5.7.5.1
ENV C5_URL https://www.concrete5.org/download_file/-/view/81601/
ENV C5_MD5 a412a72358197212532c92803d7a1021

# Install pre-requisites for Concrete5
RUN apt-get -y update && \
      DEBIAN_FRONTEND=noninteractive apt-get -y install \
      php5-curl \
      php5-gd \
      php5-mysql \
      unzip \
      wget && \
    apt-get clean && rm -r /var/lib/apt/lists/*

# Copy apache2 conf dir & Download Concrete5
# Perl script to enable ability to activate 'Pretty URLs' and redirection in .htaccess by 'AllowOverride'
# - it matches a multi-line string and replaces 'None' with 'FileInfo'
RUN perl -i.bak -0pe 's/<Directory \/var\/www\/>\n\tOptions Indexes FollowSymLinks\n\tAllowOverride None/<Directory \/var\/www\/>\n\tOptions Indexes FollowSymLinks\n\tAllowOverride FileInfo/' /etc/apache2/apache2.conf && \
    cp -r /etc/apache2 /usr/local/etc/apache2 && \
    cd /usr/local/src && \ 
    wget --no-verbose $C5_URL -O concrete5.zip && \
    echo "$C5_MD5  concrete5.zip" | md5sum -c - && \
    unzip -qq concrete5.zip && \
    rm -v concrete5.zip && \
    rm -v /var/www/html/index.html

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log

# Persist website user data, logs & apache config
VOLUME [ "/var/www/html", "/var/log/apache2", "/etc/apache2" ]

EXPOSE 80 443
WORKDIR /var/www/html

COPY docker-entrypoint /docker-entrypoint

ENTRYPOINT ["/docker-entrypoint"]
CMD ["apache2-foreground"]
