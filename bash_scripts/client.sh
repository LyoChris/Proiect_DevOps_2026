#!/bin/bash

SERVER_IP=$1
PORT=8080
FILE_TO_SEND=$2

if [ -z "$SERVER_IP" ] || [ -z "$FILE_TO_SEND" ]; then
    echo "Usage: $0 <server_ip> <file_to_send>"
    exit 1
fi

if [ ! -f "$FILE_TO_SEND" ]; then
    echo "Fisierul nu exista."
    exit 1
fi

echo "Se trimite fisierul $FILE_TO_SEND catre $SERVER_IP:$PORT"

nc "$SERVER_IP" "$PORT" < "$FILE_TO_SEND"

echo "Fisier trimis cu succes."
