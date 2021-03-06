#!/bin/bash

set -e
clear

org_dir=$(pwd)
script_dir=$(cd "$( dirname "$0" )" && pwd)
cd "$script_dir"
cd ..
echo "==> Changed directory to project root $(pwd)"


sig='\/\* CSS Global Vars Include \*\/'
repl=''\
':root {\n'\
'  --base-font-size   : 10px;\n'\
'  --small-font-size  : 12px;\n'\
'  --normal-font-size : 14px;\n'\
'  --large-font-size  : 16px;\n'\
'  --sans-serif       : "Open Sans", Verdana, Geneva, sans-serif;\n'\
'  --serif            : Georgia, "Times New Roman", Times, serif;\n'\
'  --monospace        : "Courier New", Courier, monospace;\n'\
'  --primary-color    : #085A78;\n'\
'  --bewitched-tree   : #24CCB3;\n'\
'  --mystical-green   : #90CCC4;\n'\
'  --light-heart-blue : #A4EBE5;\n'\
'  --glass-gall       : #C3ECF2;\n'\
'  --silly-fizz       : #BAEFD1;\n'\
'  --brain-sand       : #D8D3B5;\n'\
'  --mustard-addicted : #D6BC7F;\n'\
'  --magic-powder     : #EBD0B3;\n'\
'  --true-blush       : #F2AEA4;\n'\
'  --merry-cranesbill : #FC626E;\n'\
'  --hr               : 1px solid #C3ECF2;\n'\
'  --light            : 300;\n'\
'}'


echo '==> Replacing'
while read F; do
    echo "$F"
    tmpF="$F"'.sedtmp'
    cp "$F" "$tmpF"
    sed -n '1h;1!H;${;g;s/\('"$sig"'\).*\('"$sig"'\)/\1\n'"$repl"'\n\2/g;p;}' "$tmpF" > "$F"
    rm "$tmpF"
done < <(find ./ -type f -iregex .*mythcss -exec grep -H -i "$sig" "{}" \; | cut -d ':' -f 1 | uniq)


echo '==> Build all Myth CSS'
for f in $(find ./ -type f -iregex .*mythcss |grep -v "build\/"); do
    echo $f;
    myth --compress $f "$(dirname $f)/$(basename $f '.mythcss').css";
done;


cd $org_dir 
echo '==> Done'
