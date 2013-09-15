export PS1='\W \$ '
shopt -s checkwinsize

if [ -d /etc/bashrc.d ]; then
    for rc in $(find /etc/bashrc.d -name '*.bashrc' -type f); do
        source "$rc"
    done
fi
