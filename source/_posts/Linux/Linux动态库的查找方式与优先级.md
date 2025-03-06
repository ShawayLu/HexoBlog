---
title: Linux动态库的查找方式与优先级
toc: true
date: 2022-11-10 15:56:44
updated: 2022-11-11 15:56:44
excerpt: Linux动态库的查找方式与优先级
cover: /images/cover/205913.jpg
thumbnail: /images/cover/205913.jpg
categories:
- Linux
tags:
- Linux
---

## 第一种方法:rpath

在链接时语句后面添加如下命令

```shell
#编译设置rpath
-Wl,-rpath=<rpath >
```

## 第二种方法:LD_LIBRARY_PATH

设置环境变量LD_LIBRARY_PATH

```shell
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:<path>
```

## 第三种方法:/lib、/usr/lib

/lib、/usr/lib文件夹是系统默认的搜索路径。将库文件放置在其中，运行时就可以搜索到了。

## 第四种方法:/etc/ld.so.cache

通过修改配置文件/etc/ld.so.conf中指定的动态库搜索路径，然后执行ldconfig命令来应用。

## 优先级

方法一 > 方法二 > 方法三 > 方法四
