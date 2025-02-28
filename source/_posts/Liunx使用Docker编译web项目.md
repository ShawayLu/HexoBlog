---
title: Liunx使用Docker编译web项目
date: 2025-02-25 11:20:56
updated: 2025-02-27 17:02:49
excerpt: Liunx使用Docker编译web项目
cover: /images/cover/qyccover0.jpg
thumbnail: /images/cover/qyccover0.jpg
toc: true
categories:
- Docker
tags:
- Docker
---

# Liunx使用Docker编译web 项目

作者:[Charming_Zhang](https://github.com/Ewithome)

## 1. 安装Docker

安装实例可以参考[Docker安装](https://blog.csdn.net/chexlong/article/details/127932711?ops_request_misc=%257B%2522request%255Fid%2522%253A%2522d6f5fa2196d5a15635c5398feada3de4%2522%252C%2522scm%2522%253A%252220140713.130102334.pc%255Fblog.%2522%257D&request_id=d6f5fa2196d5a15635c5398feada3de4&biz_id=0&utm_medium=distribute.pc_search_result.none-task-blog-2~blog~first_rank_ecpm_v1~rank_v31_ecpm-1-127932711-null-null.nonecase&utm_term=docker&spm=1018.2226.3001.4450)

> [下载docker地址](https://download.docker.com/linux/static/stable/x86_64/)

* 注意：建议docker 使用21以上版本，否则运行node 项目会出现错误：

```shell
node[1]: ../src/node_platform.cc:68:std::unique_ptr<long unsigned int> node::WorkerThreadsTaskRunner::DelayedTaskScheduler::Start(): Assertion `(0) == (uv_thread_create(t.get(), start_thread, this))' failed.
 1: node::Abort() [node]
 2: [node]
 3: node::WorkerThreadsTaskRunner::WorkerThreadsTaskRunner(int) [node]
 4: node::NodePlatform::NodePlatform(int, v8::TracingController*, v8::PageAllocator*) [node]
 5: node::V8Platform::Initialize(int) [node]
 6: [node]
 7:node::Start(int, char**) [node]
 8:[/lib/x86_64-linux-gnu/libc.so.6]
 9: __libc_start_main [/lib/x86_64-linux-gnu/libc.so.6]
10:_start [node]
ERROR: script returned exit code 139
```

## 2. 安装Node 镜像

### 2.1. 配置daemon.json

> daemon.json 的路径是 /etc/docker/daemon.json
>
> 为了解决不能下载镜像的问题，需要配置daemon.json

```json
{
  "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://ccr.ccs.tencentyun.com",
    "https://docker.m.daocloud.io",
    "https://docker.imgdb.de",
    "https://docker-0.unsee.tech",
    "https://docker.hlmirror.com",
    "https://docker.1ms.run",
    "https://func.ink",
    "https://lispy.org",
    "https://docker.xiaogenban1993.com"
  ]
}
```

### 2.2. 安装node

```shell
# 这里的版本要看自己web端使用的node版本
docker pull node:21.1.0
```

> 安装成功后可以通过以下命令查看

```shell
docker images
```

## 3. 在镜像中安装pnpm

> DockerFile内容

```shell
# 使用官方的 Node.js 镜像
FROM node:21.1.0 as build-stage
# 安装pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate
```

> 运行命令

```shell
docker build -t wisemap_node:1.0 .
```

## 4. 编译项目

> 需要运行的代码

```shell
docker run --rm -v /home/ServerManager:/home/ServerManager wisemap_node:1.0 /bin/bash /home/ServerManager/zzbuild.sh
```

> build.sh的代码

```shell
#!/bin/bash

#get current path and parent path
export current_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export parent_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

#set absolute path of the node component
export pnpm_store_path=$parent_path/WiseMapWebStore/.pnpm-store

#using legacy behavior of OpenSSL
export NODE_OPTIONS=--openssl-legacy-provider

#study parameter
while [ $# -gt 0 ]; do
    case "$1" in
        --help)
            echo "Options:"
            echo "  --prefix [set install prefix]"
            exit 0
            ;;
        *)
            echo "The command is not recognized: $1"
            echo "$0 --help to show help"
            exit 1
            ;;
    esac
    shift
done

#chdir
cd $current_path || exit 1

#set config of pnpm
pnpm config set store-dir $pnpm_store_path || exit 1
pnpm config set global-bin-dir $pnpm_store_path || exit 1
pnpm config set strict-ssl false || exit 1

#show config of pnpm
echo "set pnpm store-dir to $(pnpm config get store-dir)"
echo "set pnpm global-bin-dir $(pnpm config get global-bin-dir)"

#install depends
pnpm install || exit 1

#build service
pnpm run build || exit 1

```

## 5. 运行项目

```shell
docker run --rm --network -v /home/ServerManager:/home/ServerManager wisemap_node:1.0 /bin/bash /home/ServerManager/zzserver.sh
```

### 5.1 解决docker network 问题

1、开启防火墙

```shell
systemctl start firewalld
```

2、开放指定端口

```shell
firewall-cmd --zone=public --add-port=8848/tcp --permanent
```

3、重启防火墙

```shell
firewall-cmd --reload
```

4、查看端口号命令

```shell
netstat -ntlp
```

### 5.2 可以通过浏览器访问链接了

> <http://localhost:8848/>
