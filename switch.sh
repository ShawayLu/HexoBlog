#!/bin/bash

urlgit="https://shawayl.github.io"
urlgitee="https://shaway.gitee.io"

repogit="git@github.com:ShawayL/ShawayL.github.io.git"
repogitee="git@gitee.com:Shaway/shaway.git"

deployD=0

while [ $# -gt 0 ]; do # Until you run out of parameters...
    case "$1" in
        --git)
            deployD=1
            ;;
        --gitee)
            deployD=2
            ;;
        --help)
            echo "Options:"
            echo " --git   [Switch script to deploy to git]"
            echo " --gitee [Switch script to deploy to gitee]"
            exit
            ;;
    esac
    shift # Check next set of parameters.
done

if [ "$deployD" -eq 0 ] ; then
    echo "Error!please set deploy method"
    exit 1
fi

if [ "$deployD" -eq 1 ] ; then
    url=$urlgit
    repo=$repogit
else
    url=$urlgitee
    repo=$repogitee
fi


urlline=`grep "^url:" ./_config.yml -n -m 1 | awk -F ":" '{print $1}'`
repoline=`grep "^  repo:" ./_config.yml -n -m 1 | awk -F ":" '{print $1}'`

sed -i ""$urlline"c url: '"$url"'" ./_config.yml
sed -i ""$repoline"c\ \ repo: "$repo"" ./_config.yml




