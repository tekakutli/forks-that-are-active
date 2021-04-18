#!/usr/bin/env bash


REPO=$1
URL=$1
URL=$(echo $URL | cut -c 20-)
NAME=$(echo $URL | sed 's/\/.*//')
PROYECT=$(echo $URL | cut -f2 -d"/")
PROYECT=../api-forks-$PROYECT
PREFIX=https://api.github.com/repos/

mkdir -p $PROYECT
cd $PROYECT

attemptagain(){
    #tells the user to attempt again IF the getpages returned a "API limit reached" fetch
    COMMAND='bash get-forks.sh '$REPO
    bash ../github-api/github-valid.sh $1 "$COMMAND"
    if  [ -f exit-everything ]; then
        rm $1
        rm exit-everything
        exit
    fi
}

#loop to get each github pages with fork info, when receives an empty one it stops, it saves the state
getpages(){
    pagesname=rawfetch$i-pages-
    for  (( j=1; j<= $2 ; j++))
    do
        FILE=$pagesname$j
        if [ ! -f $FILE ];then
            URLatt=$1'?per_page=90&page='$j
            echo $URLatt
            curl --silent -H "Accept: application/vnd.github.v3+json" $URLatt > $FILE
            #check if github API still ok, also deletes the file if not to retrieve a correct one later
            attemptagain $FILE
            #chek if finally the end
            if cmp -s $FILE ../github-api/empty;then
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
if [ ! -f index-root ]; then
    URLatt=$PREFIX$URL
    getpages $URLatt '1'
    cat rawfetch$i | grep watchers_count | cut -c 21- | sed 's/,//' > stars$i
    cat rawfetch$i | grep updated_at | cut -c 18- | cut -c -10 > update$i
    echo $NAME > url$i
    echo 0 > index$i
fi

parse (){
    URL=$1
    i=-$2
    if [ ! -f index$i ]; then
        getpages $URL '100'
        cat rawfetch$i | grep forks_url | cut -c 19- | sed 's/",//' > apiurl$i
        cat rawfetch$i | grep forks_url | cut -c 48- | sed 's/\/forks",//' > url$i
        # add at the end if explicit, same with root case
        # | awk '$0=""$0'
        cat rawfetch$i | grep stargazers_c | cut -c 25- | sed 's/,//'  > stars$i
        cat rawfetch$i | grep updated_at | cut -c 20- | cut -c -10 > update$i

        echo 0 > index$i
    fi
    #loads the counter stored at index$i
    m=$(cat index$i)
    n=0
    cat url$i | while read l; do
        if (("$n"-gt"$m")); then
            continue
        fi
        n=$(($n+1))

        NAME=$(echo $l | sed 's/\/.*//')
        l=$PREFIX$l'/forks'

        parse "$l" "$NAME"
        echo $n > index$i
    done
}

URL=$PREFIX$URL'/forks'
echo $NAME
parse "$URL" "$NAME"

cat apiurl* > fapiurl
cat url* > furl
cat stars* > fstars
cat update* > fupdate

#removing unnecesary extention
sed 's/\/.*//' furl > ffurl
paste fupdate fstars ffurl > fff
sort -r fff > output
#input at the begining of the file
echo -e "lastseen\tstars\tusername\n$(cat output)" > output



#rm  apiurl* url* stars* update* f*

#further
