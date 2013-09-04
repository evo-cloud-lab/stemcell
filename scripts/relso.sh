#!/bin/sh

[ -z "$TC_PREFIX" ] && TC_PREFIX=x86_64-linux-

set -e
set -x

for dir in $@ ; do
    for so in $(find $_RELDIR/dev/$dir -name '*.so*' -type f -printf '%P\n'); do
        src=$_RELDIR/dev/$dir/$so
        not_stripped=$(file $src | grep -E 'ELF .+ not stripped') || true
        if [ -n "$not_stripped" ]; then
            dest=$_RELDIR/rel/$dir/$so
            mkdir -p $(dirname $dest)
            ${TC_PREFIX}strip -g $src -o $dest
            [ -x "$src" ] && chmod a+x $dest
        fi
    done

    for so in $(find $_RELDIR/dev/$dir -name '*.so*' -type l -printf '%P\n'); do
        dest=$_RELDIR/rel/$dir/$so
        mkdir -p $(dirname $dest)
        cp -af $_RELDIR/dev/$dir/$so $(dirname $dest)/
    done
done