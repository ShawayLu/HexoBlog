---
title: git基本使用流程
toc: true
date: 2023-03-06 16:54:38
updated: 2023-03-06 16:54:38
excerpt: git基本使用流程
cover: /images/cover/640.png
thumbnail: /images/cover/640.png
categories:
- git
tags:
- git
---

### 配置代理

```shell
# 设置代理
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

# 取消代理
git config --global --unset http.proxy
git config --global --unset https.proxy

# 查看git配置
git config --list
git config --global --list 
```

据说https没用

### 配置正确显示中文路径

```shell
git config --global core.quotepath false
```

### 克隆代码

```shell
git clone git@github.com:ShawayL/HexoBlog.git
```

### 拉取代码

```shell
git pull
```

### 添加暂存区

```shell
git add .
git add [file1] [file2] ...
git add [dir]
```

### 提交暂存区文件

```shell
git commit -m "message"
```

### 把本地提交推送到远程

```shell
git push
```

