About
===

**[docker-mysql-backup-restore-s3](https://github.com/davidegironi/docker-mysql-backup-restore-s3)** is Docker app backup and restore MySQL using AWS S3 as storage.

## Basic Backup usage

```sh
$ docker run -e ACTION=backup -e S3_ACCESSKEYID=awskey -e S3_SECRETACCESSKEY=awssecret -e S3_BUCKET=s3bucket -e S3_PREFIX=backup -e S3_REGION=awsregion -e MYSQL_USER=user -e MYSQL_PASSWORD=password -e MYSQL_HOST=localhost -e S3_FILENAME=latestbackup -e MULTI_FILES=yes davidegironi/docker-mysql-backup-restore-s3
```
## Basic Restore usage

```sh
$ docker run -e ACTION=restore -e MYSQLDUMP_DATABASE=test -e MYSQLDUMP_TODATABASE=newtest -e S3_ACCESSKEYID=awskey -e S3_SECRETACCESSKEY=awssecret -e S3_BUCKET=s3bucket -e S3_REGION=awsregion -e S3_PREFIX=backup -e MYSQL_USER=user -e MYSQL_PASSWORD=password -e MYSQL_HOST=localhost -e S3_FILENAME=latestbackup -e MULTI_FILES=yes -davidegironi/docker-mysql-backup-restore-s3
```

## Environment variables

- `ACTION` backup or restore actions, valid values are 'backup' or 'restore' (default: 'backup')
- `MYSQLDUMP_OPTIONS` mysqldump options (default: --quote-names --quick --add-drop-table --add-locks --allow-keywords --disable-keys --extended-insert --single-transaction --comments --net_buffer_length=16384 --opt --skip-extended-insert)
- `MYSQLRESTORE_TODATABASE` database restore name *required for 'restore'*
- `MYSQLDUMP_DATABASE` list of databases you want to backup (default: --all-databases)
- `MYSQL_HOST` the mysql host *required*
- `MYSQL_PORT` the mysql port (default: 3306)
- `MYSQL_USER` the mysql user *required*
- `MYSQL_PASSWORD` the mysql password *required*
- `S3_ACCESSKEYID` your AWS access key *required*
- `S3_SECRETACCESSKEY` your AWS secret key *required*
- `S3_BUCKET` your AWS S3 bucket path *required*
- `S3_PREFIX` path prefix in your bucket (default: 'backup')
- `S3_FILENAME` a consistent filename to overwrite with your backup. If not set will use a timestamp.
- `S3_REGION` the AWS S3 bucket region *required*
- `S3_ENDPOINT` the AWS Endpoint URL, for S3 Compliant APIs
- `S3_S3V4` set to `yes` to enable AWS Signature Version 4 (default: no)
- `MULTI_FILES` Allow to have one file per database if set `yes` (default: no)

## License

Copyright (c) Davide Gironi, 2020  
This is an open source software licensed under the [GPLv3 license](http://opensource.org/licenses/GPL-3.0)

## Original work

Original work Copyright (c) Johannes Schickling <schickling.j@gmail.com> https://github.com/schickling/dockerfiles  
MIT License Copyright (c) 2017 Johannes Schickling  
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

x