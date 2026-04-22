#!/bin/bash

PORT=8080
FILE_NAME=$1
SAVE_DIR="received_files"

if [ -z "$FILE_NAME" ]; then
    echo "Usage: $0 <file_name>"
    exit 1
fi

mkdir -p "$SAVE_DIR"

echo "Serverul asculta pe portul $PORT..."
echo "Fisierul va fi salvat in $SAVE_DIR/$FILE_NAME"

nc -l "$PORT" > "$SAVE_DIR/$FILE_NAME"

echo "Fisier primit cu succes."
