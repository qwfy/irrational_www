#!/bin/bash

set -e

echo "==> Please make sure commited"
git status
echo "-----------------------------"

org_dir=$(pwd)
src_dir='/data/src/beauty/www'

cd "$src_dir"
prod_name="beauty_www_$(date '+%Y-%m-%d_%H-%M-%S')_$(git rev-parse HEAD | cut -b 1-7).tgz"
prod_path="/data/src/beauty/release/$prod_name"

echo "==> Creating archive: $prod_path"
cd "$src_dir/build/web/"
tar -czf "$prod_path" *

echo "==> Uploading to server"
scp -i /data/src/beauty/aixon.pem "$prod_path" incomplete@54.84.160.165:/home/incomplete/release/

echo "==> Deploying"
ssh -T -i /data/src/beauty/aixon.pem incomplete@54.84.160.165 << SSHCMD
set -e
sudo su

service apache2 stop
rm -rf /var/www/beauty/html/*
cd /var/www/beauty/html/
cp /home/incomplete/release/$prod_name ./
tar xzf $prod_name
rm $prod_name
find ./ -type f -exec chmod 644 {} \;
find ./ -type f -exec chown www-data:www-data {} \;
find ./ -type d -exec chmod 755 {} \;
find ./ -type d -exec chown www-data:www-data {} \;
chown root:root .
echo 'ls -l is'
ls -l
service apache2 start

exit
exit
SSHCMD

cd "$org_dir"
echo "==> Done"
