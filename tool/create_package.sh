#!/bin/bash

set -e

org_dir=$(pwd)
src_dir='/data/src/beauty/www'

cd "$src_dir"
prod_name="beauty_www_$(date '+%Y%m%d_%H%M%S')_$(git rev-parse HEAD | cut -b 1-7).tgz"
prod_path="/data/src/beauty/release/$prod_name"

echo "==> Creating archive: $prod_path"
cd "$src_dir/build/web/"
tar -czf "$prod_path" *

echo "==> Uploading to server"
scp -i /data/src/beauty/aixon.pem "$prod_path" incomplete@54.84.160.165:/home/incomplete/release/

cd "$org_dir"
echo "==> Done"
