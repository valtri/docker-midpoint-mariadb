FROM valtri/docker-midpoint:latest
MAINTAINER František Dvořák <valtri@civ.zcu.cz>

ENV v 3.5
ENV schema config/sql/_all/mysql-3.5-all.sql

WORKDIR /root

RUN apt-get update && apt-get install -y \
    mariadb-server \
&& rm -rf /var/lib/apt/lists/*

# for repo-ninja
RUN ln -s /usr/share/java/mysql-connector-java.jar /opt/midpoint-${v}/lib/

COPY midpoint.cnf /etc/mysql/conf.d/
RUN pass='changeit' \
&& service mysql start \
&& mysql -e "CREATE DATABASE midpoint CHARACTER SET utf8 DEFAULT CHARACTER SET utf8 COLLATE utf8_bin DEFAULT COLLATE utf8_bin" \
&& mysql -e "GRANT ALL ON midpoint.* TO midpoint@localhost IDENTIFIED BY '${pass}'" \
&& mysql -u midpoint -p${pass} midpoint < /opt/midpoint-${v}/${schema}

RUN xmlstarlet ed --inplace --update '/configuration/midpoint/repository' --value '' /var/opt/midpoint/config.xml
COPY config-repo.txt .
RUN while read key value; do xmlstarlet ed --inplace --subnode /configuration/midpoint/repository --type elem --name ${key} --value ${value} /var/opt/midpoint/config.xml; done < config-repo.txt
RUN rm config-repo.txt

RUN rm -fv /var/opt/midpoint/midpoint*.db

RUN mv /docker-entry.sh /docker-entry-base.sh
COPY docker-entry.sh /
