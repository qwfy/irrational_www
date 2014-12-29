#!/bin/bash

set -e
clear

org_dir=$(pwd)
script_dir=$(cd "$( dirname "$0" )" && pwd)
cd "$script_dir"
cd ..
echo "==> Changed directory to project root $(pwd)"


echo '==> Cleaning previous build'
rm -rf build/
find ./ -type l -iregex .*packages -exec rm -rf "{}" \;
rm -rf packages/

echo '==> Build Myth CSS'
for f in $(find ./ -type f -iregex .*mythcss |grep -v "build\/"); do
    echo $f;
    myth --compress $f "$(dirname $f)/$(basename $f '.mythcss').css";
done;

echo '==> Running pub build'
cygstart -w launcher.bat pub.bat get
cygstart -w launcher.bat pub.bat build

echo '==> Cleaning'
build_web='./build/web/'

find $build_web -type f -iregex .*\.js\.map           -exec rm "{}" \;
find $build_web -type f -iregex .*\.precompiled\.js   -exec rm "{}" \;
find $build_web -type f -iregex .*\.mythcss           -exec rm "{}" \;
find $build_web -type f -iregex .*\._buildLogs\..*    -exec rm "{}" \;

echo '==> SSH into dev host to make Apache serve the newly compiled JS version'
ssh admin@dev 'cd /var/www/irrational/ && sudo rm html && sudo ln -s /home/admin/irrational/www/build/web ./html && ls -l && cd -'

cd "$org_dir"
echo '==> Done'
