#!/bin/bash

set -e
clear

org_dir=$(pwd)
src_dir='/data/src/beauty/www'
cd "$src_dir"

pub get

echo '==> Build Myth CSS'
for f in $(find $src_dir -type f -iregex .*mythcss |grep -v "build\/"); do
    echo $f;
    myth --compress $f "$(dirname $f)/$(basename $f '.mythcss').css";
done;

echo '==> Changing permission'
find $src_dir/web -type f -iregex .*\.html -exec chmod 644 {} \;
find $src_dir/web -type f -iregex .*\.css -exec chmod 644 {} \;

echo '==> Building'
pub build

echo '==> Cleaning'
built_web="$src_dir/build/web"

find $built_web -type f -iregex .*\.js\.map           -exec rm "{}" \;
find $built_web -type f -iregex .*\.precompiled\.js   -exec rm "{}" \;
find $built_web -type f -iregex .*\.mythcss           -exec rm "{}" \;
find $built_web -type f -iregex .*\._buildLogs\..*    -exec rm "{}" \;

cd "$org_dir"
echo '==> Done'
