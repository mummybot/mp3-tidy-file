# mp3-tidy-file
A bash script (tested on Mac OSX) to tidy up the naming convention for mp3 collections inconsistently format shifted from my CD collection. It is in two parts: rename the files based on the folder structure and set id3 tags.

```
Command line options:
-r          Write changes, pass any argument.
-p          The directory path of the mp3 files to be tidied.
            By default it will use the location of this script.
            Should point to ./Artist/Album/%FILES_TO_TIDY%
-y          The ablum year
-g          Short code genre. For full list see http://axon.cs.byu.edu/~adam/gatheredinfo/organizedtables/musicgenrelist.php.
            Recommended genres and codes:
            7     Hip-Hop
            8     Jazz
            9     Metal
            13    Pop
            17    Rock
            32    Classical
            52    Electronic
            57    Comedy
-h          Print this help menu

Examples:
    Dry run all mp3s in this directory
        .mp3-tidy-file.sh -p ./Mark\ Ronson/Uptown\ Special

    Tidy all mp3s in this directory
        .mp3-tidy-file.sh -p ./Mark\ Ronson/Uptown\ Special -r 1
```

By default the script runs in dry run mode and outputs the proposed changes.

## Folder and files
The folder and file naming convention is:
```
/artist/album/artist - ## - song title ft. artist.mp3
```
Place the album to rename in the artist/album structure. The mp3-tidy-file either should sit inside the album alongside the mp3s or you can pass it the relative path to the mp3s with -p

If in dry run mode the new file name looks incorrect, either make neccessary changes to files to make up shortfall or add additional formatting functions in script where highlighted.

## ID3 tagging
This uses the opens source library id3lib which once installed is accessed on the command line using id3tag.

Use homebrew to install:
```
brew install id3lib
```
http://apple.stackexchange.com/questions/3585/is-there-a-good-command-line-id3-tool-for-os-x/16145#16145

One limitation is that it only takes id3 v1 genres as a short code, and cannot be set to a custom string.
