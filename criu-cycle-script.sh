#!/bin/bash

create_dump_folder() {
    mkdir -p /home/criu-dump-location
    touch /home/criu-dump-location/dump.log /home/criu-dump-location/restore.log
}
run_app() {
    java -jar /app.jar > out.log 2>&1 &
}

get_app_pid() {
    echo `ps -ef | grep java | grep -v grep | awk '{ print $2 }'`
}

check_server_started() {
    for i in $(seq 1 100)
    do
        cat /out.log | grep "Started PetClinicApplication in" &> /dev/null
        local init=$?
        if [ ${init} -eq 0 ]; then
            break
        else
            if [ $i -eq 100 ]; then
                exit 1
            fi
            sleep 1
        fi
    done
}

initiate_dump() {
    mkdir -p /home/criu-dump-location/dump-image-store
    cd /home/criu-dump-location/dump-image-store
    check_server_started
    if [ $? -eq 0 ]; then
        criu dump -t "$1" --tcp-established -j --leave-running -v4 -o "$2"
        if [ $? -eq 0 ]; then
            echo "[ checkpoint successfull ]"
        fi
    fi    
}

initialize_restore() {
    cd /home/criu-dump-location/dump-image-store
    criu restore --tcp-established -j -v3 -o "$1"
}

remove_dump_folder() {
    rm -rf /home/criu-dump-location
}

initiate_checkpoint() {
    remove_dump_folder
    create_dump_folder
    run_app
    app_pid=$(get_app_pid)
    initiate_dump $app_pid "/home/criu-dump-location/dump.log"
}

umount -R /proc
mount -t proc proc /proc

if [ -d "/home/criu-dump-location/dump-image-store" ]; then
    initialize_restore "/home/criu-dump-location/restore.log"
else
    initiate_checkpoint
fi
