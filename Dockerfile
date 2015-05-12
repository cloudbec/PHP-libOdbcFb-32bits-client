FROM nuagebec/ubuntu32:14.04
MAINTAINER David Tremblay <david@nuagebec.ca>

#install base packages

# Install packages
RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get -y install openssh-server ca-certificates pwgen supervisor git tar vim-nox vim-syntax-go wget  --no-install-recommends && apt-get clean  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# #https://github.com/docker/docker/issues/6103
RUN mkdir -p /var/run/sshd && sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && sed -ri 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config

# define volume
VOLUME /data/persistent

# Define working directory.
WORKDIR /data

ADD set_root_pw.sh /data/set_root_pw.sh
ADD run.sh /data/run.sh




#install php and apache

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -yq install \
        curl \
        apache2 \
        libapache2-mod-php5 \
        php5-mysql \
        php5-gd \
        php5-curl \
        php-pear \
        php-mail \
        mysql-client \
        php-apc \ 
	unixodbc \ 
	unixodbc-dev \ 
	php5-interbase \
	php5-odbc \ 
	libmyodbc && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


# As suggested here : http://docs.docker.com/articles/using_supervisord/
ADD supervisord_nuagebec.conf /etc/supervisor/conf.d/supervisord_nuagebec.conf

ADD sshd.conf /etc/supervisor/conf.d/sshd.conf

RUN chmod a+x /data/*.sh




ADD supervisor_apache.conf /etc/supervisor/conf.d/apache.conf 
ADD ./config/php.ini /etc/php5/apache2/conf.d/php.ini
ADD ./config/000-default.conf /etc/apache2/sites-available/000-default.conf

#Activate php5-mcrypt
RUN php5enmod mcrypt

#Activate mod_rewrite
RUN a2enmod rewrite

#Activate SSl 
RUN a2enmod ssl

#Activate phpmod odbc
RUN php5enmod pdo_odbc


#install the odbc shit

COPY bin/libOdbcFb.so /usr/lib/i386-linux-gnu/libOdbcFb.so 

RUN ln -s /usr/lib/i386-linux-gnu/libfbclient.so.2 /usr/lib/libgds.so

COPY config/odbc.ini /etc/odbc.ini

COPY config/odbcinst.ini /etc/odbcinst.ini


RUN echo "<?php phpinfo();" > /var/www/html/index.php


EXPOSE 80 443
CMD ["/data/run.sh"]

