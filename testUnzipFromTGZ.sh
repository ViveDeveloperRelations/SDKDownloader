#!/bin/bash

# Set the directory containing the tgz files

outputdirectorybase="essence_combined_packages/"

function setup_git_repo {
    local repo_base="$1"
    mkdir -p "$repo_base"
    rm -rf "$repo_base/.git"
    rm -rf "$repo_base"/*

    # Remove any existing non-Git files in the output directory
    #find "$repo_base" -mindepth 1 -maxdepth 1 ! -name '.*' -delete
    #the above didn't delete non-dotfile directories as well as files
    rm -rf $repo_base/*

    # Copy the Git files to the output directory and initialize a new repository
    cp files_to_copy_to_repo/output_repo_gitattributes "$repo_base/.gitattributes"
    cp files_to_copy_to_repo/output_repo_gitignore "$repo_base/.gitignore"
    cp files_to_copy_to_repo/LICENSE* "$repo_base/"
    #cp files_to_copy_to_repo/package** "$repo_base/"

    git -C "$repo_base" init
    wait
    git -C "$repo_base" add -A
    git -C "$repo_base" commit -am "initial commit"
    sleep 1
}
setup_git_repo "$outputdirectorybase"

function get_version_numbers {
    directory_to_look_for_tgz_files="$1"
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
#version_numbers=($(get_version_numbers $tgzdirectory))
#TEMP: HACK: hardcode version numbers for now to keep the iteration faster
version_numbers=( "5.2.1-r.1" )

# extract packages from their downloaded locations to a git repo and check them in
function extract_packages {
    local outputdirectory=$1
    local version=$2
    shift
    shift
    local packages=("$@")    # Now $@ contains the remaining parameters

    # Unzip the tgz file into the output directory
    for package in ${packages[@]};
    do
        local tgzfile=$package/$package-$version.tgz
        local package_output_directory=$outputdirectory$package

        rm -rf "$package_output_directory"
        mkdir -p "$package_output_directory"
        printf "extracting $tgzfile to $package_output_directory\n" >&2
        tar -xzf "$tgzfile" --strip-components=1 -C "$package_output_directory/"
    done

}
function commit_main_branch {
    local outputdirectory="$1"
    local version="$2"
    mainbranch="master"
    git -C "$outputdirectory" checkout "$mainbranch"
    # Add all files to the Git repository and create a new commit
    git -C "$outputdirectory" add -A
    git -C "$outputdirectory" commit -am "version $version"
    # Tag the commit with the version number
    git -C "$outputdirectory" tag -a "versions/$version" -m "version $version"
}
function patch_for_combined_package {
    local outputdirectory="$1"

    find "$outputdirectory" -name "package.json" -type f -delete
    find "$outputdirectory" -name "package.json.meta" -type f -delete
    echo "all files in packages"
    ls files_to_copy_to_repo/packag*
    cp files_to_copy_to_repo/packag* "$outputdirectory/"
}
function commit_combined_branch {
    local outputdirectory="$1"
    local version="$2"

    combinedbranch="combined"
    combinedpackagename="com.htc.upm.wave.nativecombined"

    #create branch if branch not created in git
    if git rev-parse --verify --quiet "$combinedbranch" >/dev/null; then
        git -C "$outputdirectory" checkout "$combinedbranch"
    else
        # Create a new branch and switch to it
        git -C "$outputdirectory" checkout -b "$combinedbranch"
    fi
    
    #apply patch if needed
    #if patch file exists, apply it
    patchfile=files_to_copy_to_repo/patch_$version.diff
    if [ -f $patchfile ]; then
        echo "applying patch"
        git -C "$outputdirectory" apply $patchfile
    fi
    git -C "$outputdirectory" add -A
    git -C "$outputdirectory" commit -am "patches for creating combined version $version"
    # Tag the commit with the version number
    git -C "$outputdirectory" tag -a "combined/$version" -m "combined version $version"
    #create a tgz file of the combined output for publishing purposes
    #create directory for tgz files if it doesn't exist
    mkdir -p "$combinedpackagename"

    tar -czf "$combinedpackagename/$combinedpackagename-$version.tgz" -C "$outputdirectory" 
}


package_names=("com.htc.upm.wave.xrsdk" "com.htc.upm.wave.native"  "com.htc.upm.wave.essence" )
for version in "${version_numbers[@]}"; do
    echo " version $version"

    extract_packages $outputdirectorybase $version "${package_names[@]}" 
    commit_main_branch $outputdirectorybase $version
    patch_for_combined_package $outputdirectorybase
    commit_combined_branch $outputdirectorybase $version
done


function push_to_remote {
    local outputdirectorybase="$1"
    #origin=https://github.com/ViveDeveloperRelations/WaveNativeIndividual.git
    origin=https://github.com/ViveDeveloperRelations/WaveCombined_test.git
    git -C "$outputdirectorybase" remote add origin $origin
    git -C "$outputdirectorybase" push origin master --force
    #https://github.com/ViveDeveloperRelations/WaveNativeIndividual.git
    git -C "$outputdirectorybase" push --tags --force
}

#push_to_remote "$outputdirectorybase"
