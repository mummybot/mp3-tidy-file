# /Artist name/Album name/Artist Name - ## - Track name.mp3

#!/bin/sh

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialise variables
helpText='
Command line options:
    -r          Rename mp3 files.
    -p          The directory path of the mp3 files to be tidied.
                By default it will use the location of this script.
                Should point to ./Genre/Artist/Album/%FILES_TO_TIDY%
    -h          Print this help menu

Examples:
    Dry run all mp3s in this directory
        .mp3-tidy-file.sh -p ./Electronica/Mark\ Ronson/Uptown\ Special

    Tidy all mp3s in this directory
        .mp3-tidy-file.sh -r -p ./Electronica/Mark\ Ronson/Uptown\ Special

'
run=0
path=${PWD}
artist=""
album=""
oldfilename=""
newfilename=""

while getopts "h?rp:" opt; do
    case "$opt" in
    h|\?)
        helpText
        exit 0
        ;;
    r)  run=1
        ;;
    p)  path="$OPTARG"
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

function dirnametofilename() {
  for f in $*; do
    bn=$(basename "$f")
    ext="${bn##*.}"
    filepath=$(dirname "$f")
    dirname=$(basename "$filepath")
    mv "$f" "$filepath/$dirname $fn.$ext"
    echo $f
  done
}

function setArtistAlbumName() {
    local ary

    IFS='/' read -a ary <<< "${path}";
    artist=${ary[@]: -2:1}
    album=${ary[@]: -1:1}

    echo "Artist: " $artist
    echo "Album: " $album
}

function addartistname() {
    newfilename="${artist} - ${1}"
}

function cleanUpLeadingDir() {
    newfilename="${1/.\//}"
}

function replaceFeat() {
    # Stupid mac regex can not be set to case insensitive
    # Commmon feat usage
    newfilename=$(echo "$1" | sed "s/feat/ft/g")
    # Sentence case feat
    newfilename=$(echo "$newfilename" | sed "s/Feat/ft/g")
    #  Remove trailing period if it exists
    newfilename=$(echo "$newfilename" | sed "s/ft./ft/g")
    #  Add trailing period as it now doesn't exist
    newfilename=$(echo "$newfilename" | sed "s/ft/ft./g")

    # Remove surrounding () parentheses
    if [[ $newfilename == *\(ft.*\)* ]]; then
        newfilename=$(echo "$newfilename" | sed -E "s/\((ft[^)]*)\)/\1/g")
    fi
}

function getmp3s() {
    while IFS= read -d $'\0' -r file ; do
        oldfilename=$(basename "$file")
        newfilename="${oldfilename}"

        # Run the functions
        addartistname "$file"
        cleanUpLeadingDir "${newfilename}"
        replaceFeat "${newfilename}"

        # Check if in dry run mode
        if [[ $run != 1 ]]; then
            printf "\"$oldfilename\" to \n\"$newfilename\"\n\n"
        # In run mode
        else
            printf 'New file name: %s\n' "$newfilename"
        fi
    done < <(find "$path" -iname '*.mp3' -print0)

    # Check if in dry run mode
    if [[ $run != 1 ]]; then
        echo "If the this looks good run command with -r switch."
    # In run mode
    else
        echo "Renaming complete."
    fi
}

setArtistAlbumName
getmp3s

# # End of file