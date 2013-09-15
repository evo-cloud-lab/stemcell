source /etc/cloud.env

cloud_prompt() {
    if [ -f /var/lib/cloud/connector-id ]; then
        echo -ne "\033[0;32m$(cat /var/lib/cloud/connector-id)\033[0m:";
    else
        echo -ne "\033[1;30mno-id\033[0m:";
    fi
}

export PROMPT_COMMAND=cloud_prompt