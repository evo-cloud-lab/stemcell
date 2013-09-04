#!/bin/sh

[ -z "$TC_PREFIX" ] && TC_PREFIX=x86_64-linux-

set -e
set -x

for dir in $@ ; do
    mkdir -p $_RELDIR/rel/$dir
    cp -af $_RELDIR/dev/$dir/* $_RELDIR/rel/$dir/
    for bin in $(find $_RELDIR/rel/$dir -type f -executable); do
        not_stripped=$(file $bin | grep -E 'ELF .+ not stripped') || true
        if [ -n "$not_stripped" ]; then
            ${TC_PREFIX}strip -g $bin
            chmod a+x $bin
        fi
    done
done