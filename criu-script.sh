#!/bin/bash

create_dump_folder() {
    mkdir -p /home/criu-dump-location
    touch /home/criu-dump-location/dump.log /home/criu-dump-location/restore.log
}
run_app() {
    java -jar /app.jar &
}

get_app_pid() {
    echo `ps -ef | grep java | grep -v grep | awk '{ print $2 }'`
}

initiate_dump() {
   mkdir -p /home/criu-dump-location/dump-image-store
   cd /home/criu-dump-location/dump-image-store
   criu dump -t "$1" --tcp-established -j -v4 -o "$2"  
}

create_dump_folder
run_app
app_pid=$(get_app_pid)
initiate_dump $app_pid "/home/criu-dump-location/dump.log"

