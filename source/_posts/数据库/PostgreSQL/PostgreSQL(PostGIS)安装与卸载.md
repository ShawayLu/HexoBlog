---
title: PostgreSQL(PostGIS)安装与卸载
date: 2022-10-30 15:52:00
updated: 2022-10-30 15:53:00
excerpt: PostgreSQL(PostGIS)安装与卸载
cover: /images/cover/1050187.jpg
thumbnail: /images/cover/1050187.jpg
toc: true
categories:
- 数据库
- PostgreSQL
tags:
- PostgreSQL
- 数据库
---
# PostgreSQL(PostGIS)安装
## 第一步：安装PostgreSQL

运行postgresql-11.10-1-windows-x64.exe。

![安装1](PostgreSQL(PostGIS)安装与卸载/安装1.PNG)

选择安装目录，我的是"E:\PostgreSQL\11"。

![安装2](PostgreSQL(PostGIS)安装与卸载/安装2.PNG)

全选，next。

![安装3](PostgreSQL(PostGIS)安装与卸载/安装3.PNG)

存储路径选择默认路径，next。

![安装4](PostgreSQL(PostGIS)安装与卸载/安装4.PNG)

为数据库默认超级账户 postgres 设置密码,next。

![安装5](PostgreSQL(PostGIS)安装与卸载/安装5.PNG)

选择默认端口5432，next。

![安装6](PostgreSQL(PostGIS)安装与卸载/安装6.PNG)

区域选择：默认，一直next，等待安装完毕。

![安装7](PostgreSQL(PostGIS)安装与卸载/安装7.PNG)

是否运行拓展下载工具，取消勾选，Finish,安装完毕。

## 第二步：安装PostGIS拓展

运行postgis-bundle-pg11x64-setup-3.0.2-1.exe。

![安装8](PostgreSQL(PostGIS)安装与卸载/安装8.PNG)

勾选上Create spatial database，next。

![安装9](PostgreSQL(PostGIS)安装与卸载/安装9.PNG)

选择PostgreSQL的安装目录，我的是"E:\PostgreSQL\11"，next。

![安装10](PostgreSQL(PostGIS)安装与卸载/安装10.PNG)

输入安装中设置的默认超级账户 postgres 密码,next。

![安装11](PostgreSQL(PostGIS)安装与卸载/安装11.PNG)

输入模板空间数据库名字，**<u>需要从默认名字修改为："template_postgis"</u>** ,install。

![安装12](PostgreSQL(PostGIS)安装与卸载/安装12.PNG)

是否添加GDAL_DATA环境变量用来进行栅格转换，这个操作可能会覆盖掉原有GDAL_DATA环境变量，选择否，如有需要可重新添加。

![安装13](PostgreSQL(PostGIS)安装与卸载/安装13.PNG)

栅格驱动默认未开启，是否添加环境变量来开启，选择否，如有需要可重新添加。

![安装14](PostgreSQL(PostGIS)安装与卸载/安装14.PNG)

导出栅格功能默认未开启，是否添加环境变量来开启，选择否，如有需要可重新添加。

安装完成。



# PostgreSQL(PostGIS)卸载

## 第一步：关闭PostgreSQL服务

![pg服务](PostgreSQL(PostGIS)安装与卸载/pg服务.PNG)

关闭上图中PostgreSQL服务。

## 第二步：卸载PostGIS拓展

![卸载1](PostgreSQL(PostGIS)安装与卸载/卸载1.PNG)

运行pg安装目录下uninstall-postgis-bundle-pg11x64-3.0.2-1.exe。

![卸载2](PostgreSQL(PostGIS)安装与卸载/卸载2.PNG)

Uninstall，完成。

## 第三步：卸载PostgreSQL

![卸载3](PostgreSQL(PostGIS)安装与卸载/卸载3.PNG)

运行PostgreSQL安装目录下uninstall-postgresql.exe。

![卸载4](PostgreSQL(PostGIS)安装与卸载/卸载4.PNG)

选择第一个，Next，等待进度条结束。![卸载5](PostgreSQL(PostGIS)安装与卸载/卸载5.PNG)

删除PostgreSQL安装目录下残余文件。

![卸载6](PostgreSQL(PostGIS)安装与卸载/卸载6.PNG)

删除pgAdmin文件夹，位于C:\Users\"username"\AppData\Roaming\下。
