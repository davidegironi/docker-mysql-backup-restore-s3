FROM alpine:latest
LABEL maintainer="Davide Gironi <davide.gironi@gmail.com>"

RUN apk update
RUN apk add --no-cache \
        mysql-client
RUN apk add --no-cache \
        python3 \
        py3-pip \
    && pip3 install --upgrade pip \
    && pip3 install awscli
RUN rm -rf /var/cache/apk/*

ENV ACTION backup
ENV MYSQLDUMP_OPTIONS --quote-names --quick --add-drop-table --add-locks --allow-keywords --disable-keys --extended-insert --single-transaction --create-options --comments --net_buffer_length=16384
ENV MYSQLDUMP_DATABASE --all-databases
ENV MYSQLRESTORE_DATABASE **None**
ENV MYSQLRESTORE_TODATABASE **None**
ENV MYSQL_HOST **None**
ENV MYSQL_PORT 3306
ENV MYSQL_USER **None**
ENV MYSQL_PASSWORD **None**
ENV S3_ACCESSKEYID **None**
ENV S3_SECRETACCESSKEY **None**
ENV S3_BUCKET **None**
ENV S3_REGION **None**
ENV S3_ENDPOINT **None**
ENV S3_S3V4 no
ENV S3_PREFIX 'backup'
ENV S3_FILENAME **None**
ENV MULTI_FILES no

ADD backuprestore.sh backuprestore.sh

CMD ["sh", "backuprestore.sh"]
