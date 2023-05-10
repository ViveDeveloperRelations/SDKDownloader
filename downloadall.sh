#!/bin/bash

# Replace the package names in the array with the ones you want to download
PACKAGE_NAMES=("com.htc.upm.wave.openxr" "com.htc.upm.wave.openxr.toolkit" "com.htc.upm.wave.openxr.toolkit.samples" "com.htc.upm.wave.essence" "com.htc.upm.wave.native" "com.htc.upm.wave.xrsdk")
VIVE_REGISTRY=https://npm-registry.vive.com/

for PACKAGE_NAME in "${PACKAGE_NAMES[@]}"
do
  # Create a directory for the package and change to that directory
  mkdir -p "$PACKAGE_NAME" && cd "$PACKAGE_NAME"

  # Get all the available versions
  VERSIONS=$(npm view $PACKAGE_NAME versions --json --registry=$VIVE_REGISTRY)

  # Remove the first and last character to remove '[' and ']' from JSON array
  VERSIONS=${VERSIONS:1:-1}

  # Iterate through the versions, download, and extract each version
  for VERSION in $(echo $VERSIONS | tr -d '"' | tr ',' '\n')
  do
    echo "Downloading $PACKAGE_NAME@$VERSION"
    FILE_NAME=$(npm pack $PACKAGE_NAME@$VERSION --registry=$VIVE_REGISTRY)
    #echo "Extracting $FILE_NAME"
    #tar -xzf $FILE_NAME
    #rm $FILE_NAME
  done

  # Change back to the parent directory
  cd ..
done
