#!/bin/sh

set -e
set -x

for dir in $@ ; do
    mkdir -p $_RELDIR/rel/$dir
    cp -af $_RELDIR/dev/$dir/* $_RELDIR/rel/$dir/
done