---
title: Hexo博客基本指南
toc: true
date: 2023-03-06 16:16:02
updated: 2023-03-06 16:16:02
excerpt: Hexo博客基本指南
cover: /images/cover/736461.png
thumbnail: /images/cover/736461.png
categories:
- hexo
tags:
- hexo
---

由于本人工作在内网，博客随缘更新，因此写一个关于hexo的文档，以免每次都要重新回忆一遍

### 1.下载依赖

```shell
#全局下载
npm install hexo-cli -g
#项目中下载
npm install
```

```shell
#查看全局下载内容
npm ls -g
#查看项目下载内容
npm ls
```

### 2.hexo生成

```shell
hexo g
#或hexo generate
```

该命令执行后在hexo站点根目录下生成public文件夹

### 3.hexo清理

```shell
hexo clean
```

把生成中的`public`文件夹删除

### 4.hexo本地启动

```shell
hexo s
#或hexo server
```

启动服务，默认地址为http://localhost:4000

### 5.新建文章

```shell
hexo new [layout] <title>
```

指令执行时，Hexo 会尝试在 scaffolds 中寻找layout.md布局，若找到，则根据该布局新建文章；若未找到或指令中未指定该参数，则使用post.md新建文章。新建文章的名称在_config.yml中配置。

### 6.部署静态页面

```shell
hexo d
#或hexo deploy
```

部署站点，在本地生成`.deploy_git`文件夹，并将编译后的文件上传
