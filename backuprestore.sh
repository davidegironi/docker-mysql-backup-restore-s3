#!/bin/sh

# Docker backup and restore MySQL using AWS S3 as storage
# Copyright (c) Davide Gironi, 2020  
# This is an open source software licensed under the GPLv3 license

set -e

if [ -z "$(echo $ACTION | grep -i -E "^(backup|restore)$")" ]; then
  echo "Warning: You did not set a valid ACTION for the environment variable."
  exit 1
fi

if [ "${S3_ACCESSKEYID}" = "**None**" ]; then
  echo "Warning: You did not set the S3_ACCESSKEYID environment variable."
  exit 1
fi

if [ "${S3_SECRETACCESSKEY}" = "**None**" ]; then
  echo "Warning: You did not set the S3_SECRETACCESSKEY environment variable."
  exit 1
fi

if [ "${S3_BUCKET}" = "**None**" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ "${MYSQL_HOST}" = "**None**" ]; then
  echo "You need to set the MYSQL_HOST environment variable."
  exit 1
fi

if [ "${MYSQL_USER}" = "**None**" ]; then
  echo "You need to set the MYSQL_USER environment variable."
  exit 1
fi

if [ "${MYSQL_PASSWORD}" = "**None**" ]; then
  echo "You need to set the MYSQL_PASSWORD environment variable or link to a container named MYSQL."
  exit 1
fi

if [ -z "$(echo $MULTI_FILES | grep -i -E "^(yes|no)$")" ]; then
  echo "Warning: You did not set a valid MULTI_FILES for the environment variable."
  exit 1
fi

if [ "${MYSQLDUMP_DATABASE}" = "--all-databases" ] && [ -z "$(echo $MULTI_FILES | grep -i -E "^(yes)$")" ]; then
  echo "Warning: You can enable MULTI_FILES only if all database backup requested in MYSQLDUMP_DATABASE."
  exit 1
fi

if [ "${ACTION}" = "restore" ] && [ "${MYSQLRESTORE_DATABASE}" = "**None**" ]; then
  echo "You need to set the MYSQLRESTORE_DATABASE environment if 'restore' ACTION is set."
  exit 1
fi

if [ "${ACTION}" = "restore" ] && [ "${MYSQLRESTORE_TODATABASE}" = "**None**" ]; then
  echo "You need to set the MYSQLRESTORE_TODATABASE environment if 'restore' ACTION is set."
  exit 1
fi

if [ "${ACTION}" = "restore" ] && [ -z "$(echo $MULTI_FILES | grep -i -E "^(yes)$")" ]; then
  echo "You need to enable MULTI_FILES if 'restore' ACTION is set."
  exit 1
fi

if [ "${S3_S3V4}" = "yes" ]; then
    aws configure set default.s3.signature_version s3v4
fi

if [ "${S3_IAMROLE}" != "true" ]; then
  export AWS_ACCESS_KEY_ID=$S3_ACCESSKEYID
  export AWS_SECRET_ACCESS_KEY=$S3_SECRETACCESSKEY
  export AWS_DEFAULT_REGION=$S3_REGION
fi

#common options and arguments
if [ "${S3_ENDPOINT}" = "**None**" ]; then
  AWS_ARGS=""
else
  AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
fi
MYSQL_HOSTOPTS="-h $MYSQL_HOST -P $MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD"

if [ "${ACTION}" = "backup" ]; then
  DUMPTIME=$(date +"%Y-%m-%dT%H%M%SZ")
  # backup multiple files
  if [ ! -z "$(echo $MULTI_FILES | grep -i -E "^(yes)$")" ]; then
    if [ "${MYSQLDUMP_DATABASE}" = "--all-databases" ]; then
      DATABASES=`mysql $MYSQL_HOSTOPTS -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys|innodb)"`
    else
      DATABASES=$MYSQLDUMP_DATABASE
    fi

    for DB in $DATABASES; do
      echo "Creating individual dump of ${DB} from ${MYSQL_HOST}..."

      DUMP_FILE="/tmp/dump_${DB}.sql.gz"

      #run mysql dump
      mysqldump $MYSQL_HOSTOPTS $MYSQLDUMP_OPTIONS $DB | gzip > $DUMP_FILE

      if [ $? = 0 ]; then
        #upload to S3
        if [ "${S3_FILENAME}" = "**None**" ]; then
          S3_FILE="${DUMPTIME}.${DB}.sql.gz"
        else
          S3_FILE="${S3_FILENAME}.${DB}.sql.gz"
        fi
        S3_URI=s3://$S3_BUCKET/$S3_PREFIX/$S3_FILE
        echo "Uploading ${S3_FILE} on S3..."
        cat $DUMP_FILE | aws $AWS_ARGS s3 cp - $S3_URI
        if [ $? != 0 ]; then
          >&2 echo "Error uploading ${S3_FILE} on S3"
        fi
        rm $DUMP_FILE
      else
        >&2 echo "Error creating dump of ${DB}"
      fi
    done
  # backup on single file
  else
    if [ "${MYSQLDUMP_DATABASE}" = "--all-databases" ]; then
      DB="full"
    else
      DB=$MYSQLDUMP_DATABASE
    fi

    echo "Creating dump for ${MYSQLDUMP_DATABASE} from ${MYSQL_HOST}..."

    DUMP_FILE="/tmp/dump_${DB}.sql.gz"

    #run mysql dump
    mysqldump $MYSQL_HOSTOPTS $MYSQLDUMP_OPTIONS $MYSQLDUMP_DATABASE | gzip > $DUMP_FILE

    if [ $? = 0 ]; then
      #upload to S3
      if [ "${S3_FILENAME}" = "**None**" ]; then
        S3_FILE="${DUMPTIME}.${DB}.sql.gz"
      else
        S3_FILE="${S3_FILENAME}.${DB}.sql.gz"
      fi
      S3_URI=s3://$S3_BUCKET/$S3_PREFIX/$S3_FILE
      echo "Uploading ${S3_FILE} on S3..."
      cat $DUMP_FILE | aws $AWS_ARGS s3 cp - $S3_URI
      if [ $? != 0 ]; then
        >&2 echo "Error uploading ${S3_FILE} on S3"
      fi
      rm $DUMP_FILE
    else
      >&2 echo "Error creating dump of all databases"
    fi
  fi

  echo "MySQL backup finished"
fi

if [ "${ACTION}" = "restore" ]; then
  S3_URI=s3://$S3_BUCKET/$S3_PREFIX
  if [ "${S3_FILENAME}" = "**None**" ]; then
    echo "Searching last Backup in ${S3_URI}"
    S3_FILE=$(aws s3 ls ${S3_URI}/ | grep -i -E "($MYSQLRESTORE_DATABASE.sql.gz)" | sort | tail -n 1 | awk '{print $4}')
  else
    S3_FILE=$(aws s3 ls ${S3_URI}/ | grep -i -E "(\s$S3_FILENAME.$MYSQLRESTORE_DATABASE.sql.gz)" | sort | tail -n 1 | awk '{print $4}')
  fi
  if [ "${S3_FILE}" = "" ]; then
    echo "Can not find restore file for ${MYSQLRESTORE_DATABASE}"
    exit 1
  fi

  RESTORE_FILE="/tmp/restore_${MYSQLRESTORE_DATABASE}.sql.gz"

  echo "Downloading ${S3_FILE} from S3..."
  aws s3 cp $S3_URI/$S3_FILE $RESTORE_FILE

  echo "Restoring from ${MYSQLRESTORE_DATABASE} to ${MYSQLRESTORE_TODATABASE}"
  mysql $MYSQL_HOSTOPTS -e "DROP DATABASE IF EXISTS ${MYSQLRESTORE_TODATABASE};"
  mysql $MYSQL_HOSTOPTS -e "CREATE DATABASE ${MYSQLRESTORE_TODATABASE};"
  zcat $RESTORE_FILE | mysql $MYSQL_HOSTOPTS ${MYSQLRESTORE_TODATABASE}

  rm $RESTORE_FILE

  echo "MySQL restore finished"

fi
