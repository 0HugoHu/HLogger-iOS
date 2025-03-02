#!/bin/bash
//  generate_protos.sh
//  HLogger
//
//  Created by Hugooooo on 3/1/25.
//

# Define the destination directory for compiled Swift protobufs
PROTO_DEST="../HLogger/Schema"

# Define the source locations for proto files
PROTO_SOURCES=(
    "https://s3.us-east-2.amazonaws.com/logger.protocol/location_schema.proto"
)

# Create destination folder if it doesn't exist
mkdir -p "$PROTO_DEST"

# Download proto files
for URL in "${PROTO_SOURCES[@]}"; do
    FILE_NAME=$(basename "$URL")
    echo "Downloading $FILE_NAME..."
    if ! curl -o "$FILE_NAME" "$URL"; then
        echo "Error: Failed to download $FILE_NAME"
        exit 1
    fi
done

# Compile all downloaded proto files to Swift
for FILE in *.proto; do
    if [[ -f "$FILE" ]]; then
        echo "Compiling $FILE..."
        if ! protoc --swift_opt=Visibility=Public --swift_out="$PROTO_DEST" "$FILE"; then
            echo "Error: Compilation failed for $FILE"
            exit 1
        fi
    fi
done

# Cleanup downloaded proto files
rm -f *.proto

echo "Protobuf compilation completed successfully!"
