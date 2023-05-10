#!/bin/bash
outputdirectorybase="essence_combined_packages/"

function get_version_numbers {
    directory_to_look_for_tgz_files=$1
    #local -n version_numbers=$2             # use nameref for indirection
    local version_numbers=()
    # Loop through all the tgz files in the directory_to_look_for_tgz_files and get version numbers

    for file in "$directory_to_look_for_tgz_files"*.tgz; do
        # Check if the file is actually a tgz file
        if [ ! -f "$file" ]; then
            printf "Skipping $file: not a regular file\n" >&2
            continue
        elif ! [[ "$file" =~ \.tgz$ ]]; then
            printf "Skipping $file: not a tgz file\n" >&2
            continue
        fi
        regex=".*/(.+)-([0-9]+\.[0-9]+\.[0-9]+(-[a-z]+(\.[0-9]+)*)*)\.tgz$"
        if [[ "$file" =~ $regex ]]; then
            package_name="${BASH_REMATCH[1]}"
            version="${BASH_REMATCH[2]}"
            printf "Recognizing version from $file: package name is $package_name, version number is $version\n" >&2
            version_numbers+=("$version")
        else
            printf "Unable to extract package name and version number from $file\n" >&2
            continue
        fi
    done
    echo "${version_numbers[@]}" # Return the array elements
}

#populate version numbers based on versions seen in tgz files

tgzdirectory="com.htc.upm.wave.essence/"
versions=($(get_version_numbers $tgzdirectory))
cd $outputdirectorybase

# Loop through the versions array
for version in "${versions[@]}"
do
    # Create a new release on GitHub for the current version
    winpty gh release create $version -t versions/$version -n ""

    # Create a tgz file of the current version
    #tar -czvf $version.tar.gz $version/
    package_names=("com.htc.upm.wave.xrsdk" "com.htc.upm.wave.native"  "com.htc.upm.wave.essence" )
    
    tgzFileString=""
    for package in ${package_names[@]};
    do
        tgzfile=../$package/$package-$version.tgz
        #echo "tgzFiles: ($tgzFileString)"
        #gh release upload $version $version.tar.gz
        tgzFileString+="$tgzfile " 
    done
    # Upload the tgz file to the GitHub release for the current version
    #gh release upload $version $version.tar.gz
    winpty gh release upload versions/$version $tgzFileString
done
