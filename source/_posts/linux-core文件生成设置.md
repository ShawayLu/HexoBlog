---
title: linux core文件生成设置
toc: true
date: 2022-11-04 13:49:29
updated: 2022-11-04 13:49:29
excerpt: Linux查看、修改core文件路径以及core文件大小限制
cover: /images/cover/560047.jpg
thumbnail: /images/cover/560047.jpg
categories: 
- Linux
tags: 
- Linux
---

# 设置与查看core文件大小限制

```shell

ulimit -c unlimited   #不限制core文件大小
ulimit -c 1024        #限制大小为1024
ulimit -c             #查看core文件限制
```

# 查看core文件生成路径

```shell
#查看路径
sysctl kernel.core_pattern
#或者
cat /proc/sys/kernel/core_pattern
```

# 设置core文件生成路径

临时修改：使用sysctl -w name=value命令。
例：

```shell
sysctl -w kernel.core_pattern=/data/core/core-%e-%t-%p.core
```

永久修改:将其添加到/etc/sysctl.conf中

```shell
kernel.core_pattern=/data/core/core-%e-%t-%p.core
```

core文件路径可通过以下占位符进行丰富

%p - pid(进程id)
%u - 当前uid(用户id)
%g - 当前gid(用户组id)
%s - 导致产生core的信号
%t - core文件生成时的unix时间
%h - 主机名
%e - 导致产生core的命令名
