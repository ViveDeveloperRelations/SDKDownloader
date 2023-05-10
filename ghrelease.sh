#!/bin/bash
outputdirectorybase="essence_combined_packages/"

function get_version_numbers {
    directory_to_look_for_tgz_files="$1"
    local version_numbers=()

    # check if the directory exists
    if [[ ! -d $directory_to_look_for_tgz_files ]]; then
        echo "Directory $directory_to_look_for_tgz_files does not exist"
        return 1
    fi

    for file in "$directory_to_look_for_tgz_files"*.tgz; do
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
    echo "${version_numbers[@]}"
}

tgzdirectory="com.htc.upm.wave.essence/"

# check if the directory exists
if [[ ! -d $tgzdirectory ]]; then
    echo "Directory $tgzdirectory does not exist"
    exit 1
fi

versions=($(get_version_numbers "$tgzdirectory"))

# check if the directory exists
if [[ ! -d $outputdirectorybase ]]; then
    echo "Directory $outputdirectorybase does not exist"
    exit 1
fi

cd "$outputdirectorybase"
echo "Current directory is $PWD"

for version in "${versions[@]}"
do
    winpty gh release delete "$version" --yes
    winpty gh release delete "versions/$version" --yes
    #todo use --notes-start-tag to get the release notes from the tag
    #winpty gh release create "$version" -t "versions/$version" -n "" --verify-tag 
    winpty gh release create "versions/$version" -t "versions/$version" --verify-tag --generate-notes

    package_names=("com.htc.upm.wave.xrsdk" "com.htc.upm.wave.native"  "com.htc.upm.wave.essence" )
    
    tgzFileString=""
    for package in "${package_names[@]}";
    do
        tgzfile="../$package/$package-$version.tgz"

        if [[ ! -f $tgzfile ]]; then
            echo "File $tgzfile does not exist"
            continue
        fi

        #tgzFileString+="..\\\\$package\\\\$package-$version.tgz "
        #hack since it wais failing before
        #tgzFileString+="/g/mirrors/sdkmirrorv1/$package/$package-$version.tgz "
        #tgzFileString+="G:/mirrors/sdkmirrorv1/$package/$package-$version.tgz "
        #multiple uploads seem to file due to file path issues
        echo "winpty gh release upload "versions/$version" "/g/mirrors/sdkmirrorv1/$package/$package-$version.tgz""
        winpty gh release upload "versions/$version" "/g/mirrors/sdkmirrorv1/$package/$package-$version.tgz"
    done
    echo "Submited files to release versions/$version"
    #might need to use windows path notation here \\ instead of /
    
    #echo "winpty gh release upload "versions/$version" "$tgzFileString""
    #winpty gh release upload "versions/$version" "$tgzFileString"
    #break
done
