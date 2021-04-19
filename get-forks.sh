#!/usr/bin/env bash

#check for URL input errors
if ((echo $1 | grep -m 1 'Moved Permanently')|| (echo $1 | grep -m 1 'Not Found')); then
    printf "Wrong URL"
    exit
fi


URL=$1
#remove unneeded part
URL=$(echo $URL | cut -f-5 -d"/" | cut -c 20-)
REPO=$URL
NAME=$(echo $URL | sed 's/\/.*//')
PROYECT=$(echo $URL | cut -f2 -d"/")
FOLDER=../api-forks-$PROYECT
PREFIX=https://api.github.com/repos/
SCRIPTS=../forks-that-are-active

mkdir -p $FOLDER
cd $FOLDER
printf "[\n\n]\n" > empty

attemptagain(){
    #tells the user to attempt again IF the getpages returned a "API limit reached" fetch
    COMMAND='bash get-forks.sh '$REPO
    bash $SCRIPTS/github-valid.sh $1 "$COMMAND" || exit 1
}

#loop to get each github pages with fork info, when receives an empty one it stops, it saves the state
getpages(){
    echo $i
    pagesname=rawfetch$i-pages-
    for  (( j=1; j<= $2 ; j++))
    do
        FILE=$pagesname$j
        if [ ! -f $FILE ];then
            URLatt=$1'?per_page=90&page='$j
            #echo $URLatt
            curl --silent -H "Accept: application/vnd.github.v3+json" $URLatt > $FILE
            #check if github API still ok, also deletes the file if not to retrieve a correct one later
            attemptagain $FILE
            #chek if finally the end
            if cmp -s $FILE empty;then
                rm $FILE
                break
            fi
        else
            continue
        fi
    done
    cat $pagesname* > rawfetch$i 2> /dev/null
    rm $pagesname* 2> /dev/null
}

#the root page fetch is different from the rest, this is 'raw' while the others fetch the 'forks'
i=-root
if [ ! -f index$i ]; then
    curl --silent -H "Accept: application/vnd.github.v3+json" $PREFIX$URL > rawfetch$i
    attemptagain rawfetch$i
    cat rawfetch$i | grep -m 1 watchers_count | head -n 1 | cut -c 21- | sed 's/,//' > stars$i
    cat rawfetch$i | grep -m 1 updated_at | head -n 1 | cut -c 18- | cut -c -10 > update$i
    cat rawfetch$i | grep -m 1 pushed_at | head -n 1 | cut -c 17- | cut -c -10 > pushed$i
    echo $NAME/$PROYECT > url$i
    echo 0 > index$i
fi

parse (){
    URL=$1
    i=-$2
    if [ ! -f index$i ]; then
        getpages $URL '100'
        #cat rawfetch$i | grep forks_url | cut -c 19- | sed 's/",//' > apiurl$i
        cat rawfetch$i | grep forks_url | cut -c 48- | sed 's/\/forks",//' > url$i
        # add at the end if explicit, same with root case
        # | awk '$0=""$0'
        cat rawfetch$i | grep stargazers_c | cut -c 25- | sed 's/,//'  > stars$i
        cat rawfetch$i | grep updated_at | cut -c 20- | cut -c -10 > update$i
        cat rawfetch$i | grep pushed_at | cut -c 19- | cut -c -10 > pushed$i
        touch index$i
    fi
    cat url$i | while read l; do
        NAME=$(echo $l | sed 's/\/.*//')
        l=$PREFIX$l'/forks'
        parse "$l" "$NAME"
    done
}

URL=$PREFIX$URL'/forks'
parse "$URL" "$NAME"

#cat apiurl* > fapiurl
cat url* > furl
cat stars* > fstars
cat update* > fupdate
cat push* > fpush

#removing unnecesary extention
sed 's/\/.*//' furl > ffurl
paste fpush fupdate fstars ffurl > fff
sort -r fff > output
#input at the begining of the file
echo -e "lastpush\tlastactivity\tstars\tusername\n$(cat output)" > output
mv output ../forks-$PROYECT


#rm empty apiurl* url* stars* update* index* f*
