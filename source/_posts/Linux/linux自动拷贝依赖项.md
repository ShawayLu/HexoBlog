---
title: linux自动拷贝依赖项
date: 2022-10-31 10:51:00
updated: 2022-10-31 10:51:00
excerpt: Linux拷贝程序依赖的所有动态库、自动检测部署环境是否缺失拷贝的动态库.方便服务部署
cover: /images/cover/736461.png
thumbnail: /images/cover/736461.png
toc: true
categories:
- Linux
tags:
- Linux
- 运维
---

​    一般来说如果server在一台机器上部署好了之后再拷贝到别的机器上会出现动态库缺失的情况，需要在两台机器来回拷贝动态库十分麻烦，于是需要一个脚本，用来一键拷贝依赖的所有动态库，在需要部署的机器上会检测每个动态库是否缺失并且把缺失的动态库拷贝到指定目录下。

先放出脚本

```shell
#!/bin/bash

if [ "$#" = "0" ]; then
    echo "Error: please add option.";
    exit 1
fi

ACTION=make #[make|check-and-use]

#应用程序的安装目录
APPDIR=/opt/app
#应用程序所有依赖项的存放目录
APPDEPALL=$APPDIR/dependencies/dep-all
#应用程序在实际部署时缺少的动态库要拷贝到目录，这个目录要在应用程序运行前加到LD_LIBRARY_PATH环境变量里
APPDEP=$APPDIR/dependencies/dep

while [ $# -gt 0 ]; do    # Until you run out of parameters...
    case "$1" in
        --make)
            ACTION=make
            ;;
        --check-and-use)
            ACTION=check-and-use
            ;;
        --help)
            echo "Options:"
            echo "  --make          [Make a dependency package]"
            echo "  --check-and-use [Check and use dependent packages]"
            echo "  --help          [show help]"
            exit
            ;;
        *)
            echo >&2 'copyDependencies.sh:' $"unrecognized option" "\`$1'"
            echo >&2 $"Try \`copyDependencies.sh --help' for more information."
            exit 1
            ;;
    esac
    shift   # Check next set of parameters.
done

if [ "$ACTION" = "make" ]; then
    #在这里可以根据自己的需要设置LD_LIBRARY_PATH,让ldd命令可以正确的找到动态库
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
    #下面这个命令通过管道和ldd命令搜索出来应用程序以来的所有的动态库，并将他们拷贝到APPDEPALL目录
    find "$APPDIR/" -type f | grep -v "^$APPDEPALL/" | xargs -i file -F " // " "{}" | grep -E " // [ ]{0,}ELF" | awk -F " // " '{print $1}' | xargs -i ldd {} | awk -F " => " '{ if(NF==2) print $2}' | awk -F " [(]{1}0x[0-9a-f]{16}[)]{1}$" '{ if(NF==2) print $1}' | grep -v "^$APPDIR/" | xargs -i \cp -L -n "{}" "$APPDEPALL/"
else

    #ldconfig -p列出当前部署环境的动态库，如果没有则将动态库拷贝到APPDEP目录
    for filename in "$APPDEPALL/"* ; do
        basefilename=`basename "$filename"`
        ldre=`ldconfig -p | grep "/$basefilename\$"`
        if [ -z "$ldre" ]; then
            echo copy "$basefilename" to "$APPDEP/"
            \cp -L -n "$filename" "$APPDEP/"
        fi
    done

    #有时虽然有同名的动态库，但是两个库的版本信息不一致导致程序不能启动，这是需要通过一下命令检测版本信息，如果缺少版本信息则将动态库拷贝到APPDEP目录
    #以下命令参考了rpm的find-requires脚本，路径是/usr/lib/rpm/find-requires
    whereisobjdump=`whereis objdump`
    if [ ! "$whereisobjdump" = "objdump:" ]; then
        for checkobj in "$APPDIR/server/bin/mgserver" "$APPDIR/webserverextensions/apache2/bin/httpd" ; do
            reqverinfos=`objdump -p "$checkobj" | awk 'BEGIN { START=0; LIBNAME=""; }
            /^[ ]{0,}required from .*:$/ { START=1; }
            (START==1) && /required from / {
                sub(/:/, "", $3);
                LIBNAME=$3;
            }
            (START==1) && (LIBNAME!="") && ($4!="") {
                print LIBNAME" ----- "$4;
            }
            '`
            echo "$reqverinfos" | while read reqverinfo
            do
                LIBNAME=`echo $reqverinfo | awk -F " ----- " '{print $1}'`
                VERSION=`echo $reqverinfo | awk -F " ----- " '{print $2}'`
                if [ ! X"$LIBNAME" = X -a ! X"$VERSION" = X -a ! -f "$APPDEP/$LIBNAME" ]; then
                    ldre=`ldconfig -p | grep "/$LIBNAME\$" | awk -F " => " '{print $2}'`
                    findre=`strings "$ldre" | grep "^$VERSION\$"`
                    if [ -z "$findre" ]; then
                        echo  copy "$LIBNAME" to $APPDEP/
                        \cp -L -n "$APPDEPALL/$LIBNAME" "$APPDEP/"
                    fi
                fi
            done
        done
    else
        echo "objdump executable file not found, please check the dynamic library version information by yourself"
    fi

fi

```

解释一下

## **参数**

参数--make的作用是制作依赖项包，就是把所有的依赖项拷贝到APPDEPALL目录
参数--check-and-use在部署是用，作用是在部署环境中检测哪些动态库缺失，并把缺失的动态库拷贝到APPDEP目录里。

## **目录**

APPDIR是要部署的软件的安装目录，APPDEPALL是软件所有的动态库依赖项的存放目录，APPDEP是实际部署时哪些库缺少了就把哪些库拷贝到这些目录下。为什么要有APPDEP这个目录，是因为在制作APPDEPALL时并不会检测哪些时系统的库，如果无区别的吧这些库都加到部署环境的环境变量里会导致很多基础的命令都用不了（亲测是这样的，因为一些底层的库不匹配，因此需要谨慎）。

## **拷贝**

拷贝命令有点长，解释一下

find "$APPDIR/" -type f | grep -v "^$APPDEPALL/"
查找软件安装目录下的所有文件，并过滤掉APPDEPALL目录下的动态库

find "$APPDIR/" -type f | grep -v "^$APPDEPALL/" | xargs -i file -F " // " "{}" | grep -E " // [ ]{0,}ELF" | awk -F " // " '{print $1}'
在上一步的查找结果里筛选出来动态库，根据file命令筛选

find "$APPDIR/" -type f | grep -v "^$APPDEPALL/" | xargs -i file -F " // " "{}" | grep -E " // [ ]{0,}ELF" | awk -F " // " '{print $1}' | xargs -i ldd {} | awk -F " => " '{ if(NF==2) print $2}' | awk -F " [(]{1}0x[0-9a-f]{16}[)]{1}$" '{ if(NF==2) print $1}' | grep -v "^$APPDIR/" | xargs -i \cp -L -n "{}" "$APPDEPALL/"
用ldd命令查看这些动态库的依赖项，并排除掉APPDIR目录下的动态库，最后进行拷贝

## **使用**

用ldconfig -p列出当前部署环境的动态库，如果没有则将动态库拷贝到APPDEP目录

有时虽然有同名的动态库，但是两个库的版本信息不一致导致程序不能启动，这是需要通过一下命令检测版本信息，如果缺少版本信息则将动态库拷贝到APPDEP目录，62-86行参考了rpm的find-requires脚本，路径是/usr/lib/rpm/find-requires

## **注意**

这个脚本只能尽可能包整动态库依赖的完整性，根据实际情况的不同需要人为去进行控制。
