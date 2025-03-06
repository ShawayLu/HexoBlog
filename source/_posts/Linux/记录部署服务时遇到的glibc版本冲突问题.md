---
title: 记录部署服务时遇到的glibc版本冲突问题
toc: true
date: 2023-04-01 13:57:44
updated: 2023-04-01 13:57:44
excerpt: 记录部署服务时遇到的glibc版本冲突问题
cover: /images/cover/640 (4).png
thumbnail: /images/cover/640 (4).png
categories:
- Linux
tags:
- Linux
- 问题解决
---

### 发现问题

某天在linux下部署服务时出现了因为glibc版本不匹配导致服务无法启动的问题。

```shell
/lib64/libm.so.6: version `GLIBC_2.27' not found
```

一般在打包的时候我会把编译机器上所有服务依赖的动态库拷贝到一个文件夹下，在部署服务的时候会动态检测缺少什么动态库，然后把对应的动态库拷贝到另一个文件夹再把这个文件夹加入到LD_LIBRARY_PATH环境变量，但是因为版本不匹配（`GLIBC_2.27' not found）导致的动态库冲突有时会检测不出来，这时就必须要手动拷贝，一般只拷贝libpthread.so或者libm.so这种问题都不大，但是拷贝到最后出现了这样的错误：

```shell
symbol __tunable_get_val, version GLIBC_PRIVATE not defined in file ld-linux-aarch64.so.1
```

动态链接器符号竟然找不到。

经过排查发现打包机器的glibc版本是2.31，部署机器的glibc版本时2.17，版本相差太多了。

### 尝试解决

由于动态链接器是硬编码到文件里的，而且不能随意的把其他的版本动态链接器替换到目标机器上，因此需要想办法去替换动态链接器，用到的工具有：patchelf、对应的glibc库。

```shell
patchelf --set-interpreter /glibc-2.31-binary/lib/ld-linux-aarch64.so.1 /custom/program
```

用这个命令把你的动态链接器路径硬编码到你的程序中。

在启动脚本前加上：

```shell
export LD_PRELOAD=/custom1/ld-linux-aarch64.so.1
#/glibc-2.31-binary/lib/aarch64-linux-gnu文件夹是目标版本glibc的一些库，pthread、m等
export LD_LIBRARY_PATH=/glibc-2.31-binary/lib:/glibc-2.31-binary/lib/aarch64-linux-gnu:"$LD_LIBRARY_PATH"
```

如果没有对应版本的glibc库则把打包机器的链接器拷贝过来也是一样的效果，所有服务依赖的动态库的文件夹要加入到LD_LIBRARY_PATH环境变量。

这样一番操作下来服务终于启动了起来，但是还是有一些问题，**setlocale(LC_ALL, "")**这个函数返回了空指针，调用**setlocale(LC_ALL, "C")**没有问题，服务运行中发现c++会抛异常

```
locale::facet::_S_create_c_locale name not valid
```

应该是一些本地化的配置没有设置好，或者信息丢失了，于是在启动脚本中加入

```shell
export LC_ALL=C
```

这样直接导致服务在启动的时候抛出**Could not load a transcoding service**的异常并且启动失败，原因目前还没有找到。

### 总结

以后在打包的时候打包机器的glibc版本尽量要小于等于目标机器的版本，可以选择一个较低的版本来支持各种常见的Linux发行版。

以下是常见的Linux发行版本的glibc版本（chatgpt）

```
Ubuntu：Ubuntu 14.04 LTS 及更高版本需要 glibc 2.19 或更高版本。
Debian：Debian 8 及更高版本需要 glibc 2.19 或更高版本。
CentOS：CentOS 7 需要 glibc 2.17 或更高版本，CentOS 8 需要 glibc 2.28 或更高版本。
Fedora：Fedora 26 及更高版本需要 glibc 2.25 或更高版本。
Arch Linux：Arch Linux 使用最新版本的 glibc。
```

因此打包所用的glibc尽量小于等于**2.17**

查看了一下达梦和瀚高在centos下的二进制包的glibc版本要求是2.10和2.14

用这个命令可以查看glibc最低要求

```shell
find ./ -name "lib*so*" | xargs -i strings {} | grep -i glibc_ | awk -F "@@" '{print $2}' | sort | uniq
```
