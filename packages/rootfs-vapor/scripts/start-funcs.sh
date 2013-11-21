# parse options
start_parse_kernel_cmdline() {
    for opt in $(cat /proc/cmdline) ; do
        test "${opt#sys-}" == "$opt" && continue
        local name="${opt%%=*}" val="${opt#*=}"
        name="${name#sys-}"
        name="${name//-/_}"
        test -z "$val" && val=1
        eval "opt_$name=$val"
    done
}

# is inside container
start_in_container() {
    local cntr=$(grep -F 'container' /proc/1/environ)
    test -n "$cntr"
}
