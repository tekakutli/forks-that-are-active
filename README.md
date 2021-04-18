# forks-that-are-active
see which forks of a given github repository are active

# usage
* cd forks-that-are-updated
* bash https://github.com/#owner#/#repository#
  
this will create a folder just outside the repo, named api-forks-<repository>
all those files are a 'state', incrementally used to parse the final query
this state design was chosen due to github-api download limit
if you see a "API limit reached" message just re-run the script some time later, nothing already downloaded will be re-downloaded

* jp was not used because I needed to use $ cut some things either way
*no database was used because this is meant to be an easy thing

btw you can increase the github-API download limit this way:
https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting
