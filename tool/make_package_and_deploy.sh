#!/bin/bash

release_dir='/D/Documents/Irrational/release'

set -e
clear

org_dir=$(pwd)
script_dir=$(cd "$( dirname "$0" )" && pwd)
cd "$script_dir"
cd ..
echo "==> Changed directory to project root $(pwd)"

echo "==> Check if git is commited"
# if [ -n "$(git status --porcelain)" ]; then 
#   echo 'Please `git commit` first'
#   exit 1
# fi

prod_name="irrational_www_$(date '+%Y-%m-%d_%H-%M-%S')_$(git rev-parse HEAD | cut -b 1-7).tgz"
prod_path="$release_dir/$prod_name"

echo "==> Creating archive: $prod_path"
cd build/web/
tar -czf "$prod_path" *

echo "==> Uploading to server"
scp "$prod_path" incomplete@irrational.aixon.co:/home/incomplete/release/

echo "==> Deploying"
ssh -T incomplete@irrational.aixon.co << SSHCMD
set -e
sudo su

service apache2 stop
rm -rf /var/www/irrational/html/*
cd /var/www/irrational/html/
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
