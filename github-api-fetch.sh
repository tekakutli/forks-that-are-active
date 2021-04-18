#!/usr/bin/env bash


#Obtaining all the pages of contributors using the github API

#STRING ARGUMENTS
#first: folder name
#second: <owner>/<repository>

mkdir $1
cd $1
URL=$2
#global counter

#flag for other scripts if fetch failed
rm exit-everything

fetch(){
    URLAPI='https://api.github.com/repos/'$URL
    URLAPI=$URLAPI'/contributors?per_page=90&anon=1&page='$i
    curl --silent -H "Accept: application/vnd.github.v3+json" $URLAPI > $FILE

    ../github-api/github-valid.sh $FILE "make"|| exit 1

    #if the retrieved file is empty, no further fetch in needed
    if cmp -s $FILE ../github-api/empty;then
        bash ../github-api/github-api-scrap.sh
        exit
    fi
}

#global variable
for i in {1..100}
do
    FILE='api-page'$i
    #when re runned it skips the fetch of pages already downloaded
    if [ -f $FILE ]; then
        #when re runned it re fetches each page if previously it had API limit error
       if grep -q 'API rate limit exceeded' "$FILE"; then
           fetch
       else
           continue
       fi
    else
        fetch
    fi
done
bash ../github-api/github-api-scrap.sh
