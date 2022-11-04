---
title: Linux输出重定向
toc: true
date: 2022-11-04 17:11:01
updated: 2022-11-04 17:11:01
excerpt: Linux中的输出重定向以及“＞/dev/null 2＞&1“的解释
cover: /images/cover/737400.jpg
thumbnail: /images/cover/737400.jpg
categories:
- Linux
tags:
- Linux
---

>:重定向,但是会删除原先内容

>>:重定向,不会删除原本内容,会在后边追加

linux中1代表标准输出，2代表的是标准错误输出，/dev/nulll等价于一个只写文件. 所有写入它的内容都会永远丢失

ls xxx >/dev/null 2>&1这个命令的意思就是将ls xxx命令的标准输出重定向到/dev/null中，然后将标准错误输出重定向到标准输出中,这样运行的结果就什么都不会输出了。

ls xxx >/dev/null 2>&1也可以写成ls xxx 1>/dev/null 2>&1

但是>/dev/null 2>&1的顺序不能换，如果顺序颠倒写成|
ls xxx 2>&1 1>/dev/null
的后果就是标准输出定位到了/dev/null中，但是标准错误输出还是会打印在屏幕上。

可以理解成shell脚本是从做往右读取的，如果在输出标准错误时读取到了2>&1那么就会认为标准错误要输出到标准输出中，不会往右继续读了。

```shell
[root@localhost lib64]# find ./ -name "*FDO*" | xargs ldd 2>&1 1>/dev/null
ldd: warning: you do not have execution permission for `./FDO.py'
```

可以看到如果写反了，标准错误还是会被打印出来。
