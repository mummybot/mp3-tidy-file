#!/bin/bash

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialise variables
function showHelp() {
echo "Command line options:"
echo "-r          Write changes, pass any argument."
echo "-p          The directory path of the mp3 files to be tidied."
echo "            By default it will use the location of this script."
echo "            Should point to ./Genre/Artist/Album/%FILES_TO_TIDY%"
echo "-y          The ablum year"
echo "-g          Short code genre. For full list see http://axon.cs.byu.edu/~adam/gatheredinfo/organizedtables/musicgenrelist.php."
echo "            Recommended genres and codes:"
echo "            7     Hip-Hop"
echo "            8     Jazz"
echo "            9     Metal"
echo "            13    Pop"
echo "            17    Rock"
echo "            32    Classical"
echo "            52    Electronic"
echo "            57    Comedy"
echo "-h          Print this help menu"
echo ""
echo "Examples:"
echo "    Dry run all mp3s in this directory"
echo "        .mp3-tidy-file.sh -p ./Mark\ Ronson/Uptown\ Special"
echo ""
echo "    Tidy all mp3s in this directory"
echo "        .mp3-tidy-file.sh -p ./Mark\ Ronson/Uptown\ Special -r 1"
echo ""
}

run=0
path="${PWD}"

artist=""
album=""
song=""
year=""
track=""
trackName=""
trackTotal=""
genre=""

oldfilename=""
newfilename=""

genres="Electronica Hip-Hop Rock Metal Classical Comedy Jazz Pop"

while getopts "h?r:p:y:g:" opt; do
    case "$opt" in
    h|\?)
        showHelp
        exit 0
        ;;
    r)  run=1
        ;;
    p)  path="$OPTARG"
        ;;
    y)  year="$OPTARG"
        ;;
    g)  genre="$OPTARG"
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

# =================================================
# Set up and normalise shared data
# =================================================
function getAbsPath() {
    local absPath=$(cd "$(dirname "$path")"; pwd)
    local count=0
    local ary

    IFS='/' read -a ary <<< "${path}";

    for i in "${ary[@]}"
    do
        if [[ "$absPath" != *"$i"* ]] && [[ "$i" != "." ]]; then
            absPath=$absPath"/"$i
        fi
    done
    path=$absPath
}
getAbsPath

function setSharedMetaData() {
    local ary
    local tempGenre=""

    IFS='/' read -a ary <<< "${path}";

    # Artist
    artist=${ary[@]: -2:1}
    # Album
    album=${ary[@]: -1:1}

    # trackTotal
    trackTotal=$(find "$path" -name "*.mp3" | wc -l)
    # Trim white space on trackTotal
    trackTotal=$(echo "$trackTotal" | sed -E "s/^ *//" | sed -E "s/ *$//")

    echo "Id3 shared MetaData"
    echo "==================="
    echo "Artist: "$artist
    echo "Album: "$album
    echo "Year: "$year
    echo "Genre: "$genre
    echo "trackTotal: "$trackTotal
    echo ""
}
setSharedMetaData

# =================================================
# Format files and folders
# Add new formatting functions as neccessary based on further found idiosyncracies
# =================================================
function cleanUpLeadingDir() {
    newfilename="${newfilename/.\//}"
}

function manageHyphensAndNumbering() {
    #Random brackets around numbers?!?!
    newfilename=$(echo "$newfilename" | sed -E "s/\(([0-9]*)\)/\1/g")
    # Hyphens
    newfilename=$(echo "$newfilename" | sed -E "s/ - /-/g")
    # http://regexpal.com/
    # Test data:
        # 01 - Uptown’s First Finale (feat. Stevie Wonder & Andrew Wyatt).mp3
        # 01 - - Uptown’s First Finale (feat. Stevie Wonder & Andrew Wyatt).mp3
        # 01-Uptown’s First Finale (feat. Stevie Wonder & Andrew Wyatt).mp3
        # 01 Uptown’s First Finale (feat. Stevie Wonder & Andrew Wyatt).mp3
        # - 01 Uptown’s First Finale (feat. Stevie Wonder & Andrew Wyatt).mp3
        #  - 01 Uptown’s First Finale (feat. Stevie Wonder & Andrew Wyatt).mp3
        # Mark Ronson - 01 - Uptown’s First Finale (feat. Stevie Wonder & Andrew Wyatt).mp3
        # Mark Ronson-01-Uptown’s First Finale (feat. Stevie Wonder & Andrew Wyatt).mp3
        # Mark Ronson- 01 -Uptown’s First Finale (feat. Stevie Wonder & Andrew Wyatt).mp3
    newfilename=$(echo "$newfilename" | sed -E "s/[\s]*-*\s*([0-9][0-9]+)\s*-*\s*-*\s*/ - \1 - /")
}

# Remove artist name in case it is already there. 
# We will add it later - this prevents duplicates.
function removeArtistName() {
    newfilename=$(echo "$newfilename" | sed "s/$artist//g")
}

function addArtistName() {
    newfilename="${artist}${newfilename}"
}

function replaceFeaturing() {
    # Stupid mac regex can not be set to case insensitive
    # Commmon feat usage
    newfilename=$(echo "$newfilename" | sed "s/feat/ft/g")
    # Sentence case feat
    newfilename=$(echo "$newfilename" | sed "s/Feat/ft/g")
    # Sentence case feat
    newfilename=$(echo "$newfilename" | sed "s/(with/(ft /g")
    #  Remove trailing period if it exists
    newfilename=$(echo "$newfilename" | sed "s/ft./ft/g")
    #  Add trailing period as it now doesn't exist
    newfilename=$(echo "$newfilename" | sed "s/ft/ft./g")

    # Remove surrounding () parentheses
    if [[ $newfilename == *\(ft.*\)* ]]; then
        newfilename=$(echo "$newfilename" | sed -E "s/\((ft[^)]*)\)/\1/g")
    fi
}

function cleanUpDoubles() {
    # double or more hyphens
    newfilename=$(echo "$newfilename" | sed -E "s/[-]+/-/g")
    # double or more white space
    newfilename=$(echo "$newfilename" | sed -E "s/[ ]+/ /g")
    #double space & hypens
    newfilename=$(echo "$newfilename" | sed -E "s/[ -]+[ -]+/ - /g")
}

function renameFiles() {
    while IFS= read -d $'\0' -r file ; do
        oldfilename=$(basename "$file")
        newfilename="${oldfilename}"

        # Run the formatting functions
        cleanUpLeadingDir
        manageHyphensAndNumbering
        removeArtistName
        addArtistName
        replaceFeaturing
        cleanUpDoubles

        # Check if in dry run mode
        if [[ $run != 1 ]]; then
            printf "\"$oldfilename\" to \n\"$newfilename\"\n\n"
        # In run mode
        else
            mv "$file" "$path/$newfilename" && printf  "\"$newfilename\" successfully renamed.\n\n"

        fi
    done < <(find "$path" -iname '*.mp3' -print0)

    # Check if in dry run mode
    if [[ $run != 1 ]]; then
        echo "If the conversion looks good run command with -r switch."
    # In run mode
    else
        echo "Renaming complete."
    fi
}

read -p "Do you want to rename files? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    renameFiles
fi


# =================================================
# Format id3 v1 & v2 flags
# =================================================
function getTrackName() {
    trackName=$(echo "$1" | sed -E "s/.* - [0-9]* - (.*)\.mp3/\1/g")
}

function formatId3Tags () {
    trackNumber=0
    while IFS= read -d $'\0' -r file ; do
        
        getTrackName "$(basename "$file")"

        let trackNumber=trackNumber+1

        # Check if in dry run mode
        if [[ $run != 1 ]]; then
            printf "Setting id3 v1 & v2 tags of \"$(basename "$file")\"\n"
            printf "Artist: $artist\nAlbum: $album\nTrack Name: $trackName\nComment: ""\nDescription: ""\nYear: $year\nTrack Number: $trackNumber\nTrack Total: $trackTotal\nGenre: $genre\n\n"
            # echo id3tag -a "\"$artist\"" -A "\"$album\"" -s "\"$trackName\"" -c "\"\"" -C "\"\"" -y "\"$year\"" -t "\"$trackNumber\"" -T "\"$trackTotal\"" -gSHORT  "\"$genre\"" "\"$file\""
        # In run mode
        else
            id3tag -a "$artist" -A "$album" -s "$trackName" -c "" -C "" -y "$year" -t "$trackNumber" -T "$trackTotal" -g  "$genre" "$file"
        fi
    done < <(find "$path" -iname '*.mp3' -print0)

    # Check if in dry run mode
    if [[ $run != 1 ]]; then
        echo "If the conversion looks good run command with -r switch."
    # In run mode
    else
        echo "Tagging complete."
    fi
}

read -p "Do you want to format id3 tags? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    formatId3Tags
fi

# # End of file