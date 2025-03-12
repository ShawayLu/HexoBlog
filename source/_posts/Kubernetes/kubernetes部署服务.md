---
title: kubernetes部署服务
toc: true
date: 2025-03-12 09:48:00
updated: 2025-03-12 09:48:00
excerpt: kubernetes部署服务
cover: /images/cover/1050187.jpg
thumbnail: /images/cover/1050187.jpg
categories:
- kubernetes
tags:
- kubernetes
---

目录
- [Pod](#pod)
  - [基础命令](#基础命令)
  - [YAML方式创建Pod](#yaml方式创建pod)
  - [实际部署](#实际部署)
- [Deployment](#deployment)
  - [基础命令](#基础命令-1)
  - [YAML方式创建Deployment](#yaml方式创建deployment)
  - [实际部署](#实际部署-1)
- [Service](#service)
  - [基础命令](#基础命令-2)
  - [实际部署](#实际部署-2)
- [PVC](#pvc)
  - [实际应用](#实际应用)

列举一下会用到的docker国内加速镜像  
将以下内容写入`/etc/docker/daemon.json`即可

`daemon.json`

```json
{
  "registry-mirrors": [
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

### Pod

#### 基础命令

创建一个nginx Pod

```shell
#创建一个nginx pod
#--image 指定镜像
#-n 指定命名空间
kubectl run mynginx --image=nginx:1.14 -n swgx
#镜像也可以指定完整镜像地址
kubectl run mynginx --image=docker.1ms.run/nginx:latest -n swgx
```

获取Pod的信息

```shell
#获取pod信息
#-o wide 显示更详细的信息
kubectl get pod -n swgx
kubectl get pod -o wide -n swgx
```

查看指定Pod的详情

```shell
#查看pod详细信息
kubectl describe pod mynginx -n swgx
```

查看Pod的运行日志（容器启动命令的输出内容）

```shell
#查看pod的运行日志
kubectl logs mynginx -n swgx
```

测试部署成功的nginx

```shell
#查看部署成功的nginx，ip可以在'kubectl get pod -o wide -n swgx'这条命令看到
curl 172.168.224.37:80
```

以命令行的形式进入pod

```shell
#以命令行的形式进入pod
kubectl exec -n swgx -it mynginx -- /bin/bash
```

删除Pod

```shell
#删除pod
kubectl delete pod mynginx -n swgx
```

#### YAML方式创建Pod

创建`nginx-swgx.yaml`并写入如下内容

`nginx-swgx.yaml`

```yaml
apiVersion: v1
#类型
kind: Pod
metadata:
  #Pod名称
  name: mynginx
  #命名空间
  namespace: swgx
spec:
  #容器
  containers:
    #容器名称
    - name: nginx
      #容器镜像
      image: docker.1ms.run/nginx:latest
      #容器端口
      ports:
        - containerPort: 80
      #容器挂载目录
      volumeMounts:
        - name: nfs-data
          mountPath: /usr/share/nginx/html
  #目录
  volumes:
    #目录
    - name: nfs-data
      #nsf服务
      nfs:
        server: 172.16.104.24
        path: /home/nfs-master1/test-master1-data-storage-pvc-e94219f3-2ef7-4056-a3b1-d830e4b5bda0/wisemap/WiseMapGisServer-v6.2.0-28067/webserverextensions/www/help/webapi
```

创建Pod

```shell
#yaml方式创建pod
#-f 指定yaml文件
kubectl create -f nginx-swgx.yaml
```

#### 实际部署

先运行一个可以持续存在的进程保证容器持久存在，然后进入容器进行wisemap的依赖项配置

创建`wisemap_tmp.yaml`并写入如下内容，这会创建一个容器运行`tail`进程保证容器的存在

`wisemap_tmp.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: wisemap
  namespace: swgx
spec:
  containers:
    - name: wisemapserver
      image: docker.1ms.run/ubuntu:16.04
      env:
        - name: LANG
          value: C.UTF-8
        - name: LC_ALL
          value: C.UTF-8
      command: ["tail"]
      args: ["-f", "/dev/null"]
      volumeMounts:
        - name: nfs-wisemap
          mountPath: /opt/WiseMapGisServer-v6.2.0-28067
  volumes:
    - name: nfs-wisemap
      nfs:
        server: 172.16.104.24
        path: /home/nfs-master1/test-master1-data-storage-pvc-e94219f3-2ef7-4056-a3b1-d830e4b5bda0/wisemap/WiseMapGisServer-v6.2.0-28067
```

然后进入容器进行依赖项配置并测试服务能否启动，测试完成后删除Pod以及`wisemap_tmp.yaml`

```shell
#进入容器
kubectl exec -n swgx -it wisemap -- /bin/bash
#配置wisemap完成之后删除Pod
kubectl delete pod wisemap -n swgx
```

接下来正式创建wisemap Pod  
创建`wisemap.yaml`并写入如下内容

`wisemap.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: wisemap
  namespace: swgx
spec:
  containers:
    - name: wisemapserver
      image: docker.1ms.run/ubuntu:16.04
      env:
        - name: LANG
          value: C.UTF-8
        - name: LC_ALL
          value: C.UTF-8
      command: ["/opt/WiseMapGisServer-v6.2.0-28067/server/bin/mgserver.sh"]
      volumeMounts:
        - name: nfs-wisemap
          mountPath: /opt/WiseMapGisServer-v6.2.0-28067
    - name: wisemaphttp
      image: docker.1ms.run/ubuntu:16.04
      env:
        - name: LANG
          value: C.UTF-8
        - name: LC_ALL
          value: C.UTF-8
      command:
        [
          "/opt/WiseMapGisServer-v6.2.0-28067/webserverextensions/apache2/bin/apachectl",
        ]
      args: ["-D", "FOREGROUND"]
      ports:
        - containerPort: 8008
      volumeMounts:
        - name: nfs-wisemap
          mountPath: /opt/WiseMapGisServer-v6.2.0-28067
  volumes:
    - name: nfs-wisemap
      nfs:
        server: 172.16.104.24
        path: /home/nfs-master1/test-master1-data-storage-pvc-e94219f3-2ef7-4056-a3b1-d830e4b5bda0/wisemap/WiseMapGisServer-v6.2.0-28067
```

创建wisemap Pod

```shell
kubectl create -f ./wisemap.yaml
```

发送一个创建session的请求来验证是否部署成功

```shell
kubectl describe pod wisemap -n swgx | grep "^IP: " | awk '{print $2}' | xargs -i curl 'http://{}:8008/WiseMap/mapagent/mapagent.fcgi?OPERATION=CREATESESSION&VERSION=4.0.0&LOCALE=&CLIENTAGENT=&SESSION=' -w '\n'
```

### Deployment

#### 基础命令

创建Deployment

```shell
#创建一个nginx Deployment
#--image 指定镜像
#-n 指定命名空间
#--replicas 指定副本数量
kubectl create deployment mynginx --image=docker.1ms.run/nginx:latest -n swgx --replicas=3
```

获取Deployment的信息

```shell
#获取Deployment的信息
kubectl get deployment -o wide -n swgx
```

查看指定Deployment的详情

```shell
#查看Deployment详细信息
kubectl describe deployment mynginx -n swgx
```

删除Deployment

```shell
#删除Deployment
kubectl delete deployment mynginx -n swgx
```

#### YAML方式创建Deployment

创建`nginx-swgx.yaml`并写入如下内容

`nginx-swgx.yaml`

```yaml
apiVersion: apps/v1
#类型
kind: Deployment
metadata:
  #Deployment名称
  name: mynginx-deployment
  #命名空间
  namespace: swgx
spec:
  #副本数
  replicas: 3
  selector:
    matchLabels:
      app: mynginx
  #Pod模板
  template:
    metadata:
      labels:
        app: mynginx
    spec:
      containers:
        - name: mynginx
          image: docker.1ms.run/nginx:latest
          ports:
            - containerPort: 80
          volumeMounts:
            - name: nfs-data
              mountPath: /usr/share/nginx/html
      volumes:
        - name: nfs-data
          nfs:
            server: 172.16.104.24
            path: /home/nfs-master1/test-master1-data-storage-pvc-e94219f3-2ef7-4056-a3b1-d830e4b5bda0/wisemap/WiseMapGisServer-v6.2.0-28067/webserverextensions/www/help/webapi
```

创建Deployment

```shell
kubectl create -f nginx-swgx.yaml
```

#### 实际部署

创建`wisemap.yaml`并写入如下内容

`wisemap.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wisemap-deployment
  namespace: swgx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wisemap
  template:
    metadata:
      labels:
        app: wisemap
    spec:
      containers:
        - name: wisemapserver
          image: docker.1ms.run/ubuntu:16.04
          env:
            - name: LANG
              value: C.UTF-8
            - name: LC_ALL
              value: C.UTF-8
          command: ["/opt/WiseMapGisServer-v6.2.0-28067/server/bin/mgserver.sh"]
          volumeMounts:
            - name: nfs-wisemap
              mountPath: /opt/WiseMapGisServer-v6.2.0-28067
        - name: wisemaphttp
          image: docker.1ms.run/ubuntu:16.04
          env:
            - name: LANG
              value: C.UTF-8
            - name: LC_ALL
              value: C.UTF-8
          command:
            [
              "/opt/WiseMapGisServer-v6.2.0-28067/webserverextensions/apache2/bin/apachectl",
            ]
          args: ["-D", "FOREGROUND"]
          ports:
            - containerPort: 8008
          volumeMounts:
            - name: nfs-wisemap
              mountPath: /opt/WiseMapGisServer-v6.2.0-28067
      volumes:
        - name: nfs-wisemap
          nfs:
            server: 172.16.104.24
            path: /home/nfs-master1/test-master1-data-storage-pvc-e94219f3-2ef7-4056-a3b1-d830e4b5bda0/wisemap/WiseMapGisServer-v6.2.0-28067
```

### Service

#### 基础命令

暴漏服务

```shell
kubectl expose deployment mynginx-deployment --port=80 --type=NodePort -n swgx
kubectl expose deployment wisemap-deployment --port=8008 --type=NodePort -n swgx
```

获取Service的信息

```shell
#获取Service的信息
kubectl get service -o wide -n swgx
```

查看指定Service的详情

```shell
#查看Service详细信息
kubectl describe service mynginx-deployment -n swgx
kubectl describe service wisemap-deployment -n swgx
```

删除Service

```shell
#删除Service
kubectl delete service mynginx-deployment -n swgx
kubectl delete service wisemap-deployment -n swgx
```

#### 实际部署

更新`wisemap.yaml`

`wisemap.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wisemap-deployment
  namespace: swgx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wisemap
  template:
    metadata:
      labels:
        app: wisemap
    spec:
      containers:
        - name: wisemapserver
          image: docker.1ms.run/ubuntu:16.04
          env:
            - name: LANG
              value: C.UTF-8
            - name: LC_ALL
              value: C.UTF-8
          command: ["/opt/WiseMapGisServer-v6.2.0-28067/server/bin/mgserver.sh"]
          volumeMounts:
            - name: nfs-wisemap
              mountPath: /opt/WiseMapGisServer-v6.2.0-28067
        - name: wisemaphttp
          image: docker.1ms.run/ubuntu:16.04
          env:
            - name: LANG
              value: C.UTF-8
            - name: LC_ALL
              value: C.UTF-8
          command:
            [
              "/opt/WiseMapGisServer-v6.2.0-28067/webserverextensions/apache2/bin/apachectl",
            ]
          args: ["-D", "FOREGROUND"]
          ports:
            - containerPort: 8008
          volumeMounts:
            - name: nfs-wisemap
              mountPath: /opt/WiseMapGisServer-v6.2.0-28067
      volumes:
        - name: nfs-wisemap
          nfs:
            server: 172.16.104.24
            path: /home/nfs-master1/test-master1-data-storage-pvc-e94219f3-2ef7-4056-a3b1-d830e4b5bda0/wisemap/WiseMapGisServer-v6.2.0-28067
---
apiVersion: v1
kind: Service
metadata:
  name: wisemap-service
  namespace: swgx
spec:
  selector:
    app: wisemap
  ports:
    - port: 8008
      targetPort: 8008
      nodePort: 38008
  type: NodePort
```

### PVC

#### 实际应用

先将服务包拷贝到pvc中

创建`wisemap_testpvc.yaml`并写入如下内容

`wisemap_testpvc.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: wisemap
  namespace: swgx
spec:
  containers:
    - name: wisemapserver
      image: docker.1ms.run/ubuntu:16.04
      env:
        - name: LANG
          value: C.UTF-8
        - name: LC_ALL
          value: C.UTF-8
      command: ["tail"]
      args: ["-f", "/dev/null"]
      volumeMounts:
        - name: nfs-wisemap
          mountPath: /opt/WiseMapGisServer-v6.2.0-28067
        - name: swgx-ce-pvc
          mountPath: /opt/test_pvc
  volumes:
    - name: nfs-wisemap
      nfs:
        server: 172.16.104.24
        path: /home/nfs-master1/test-master1-data-storage-pvc-e94219f3-2ef7-4056-a3b1-d830e4b5bda0/wisemap/WiseMapGisServer-v6.2.0-28067
    - name: swgx-ce-pvc
      persistentVolumeClaim:
        claimName: swgx-ce-pvc
```

执行如下shell来拷贝服务包

```shell
#创建Pod
kubectl create -f wisemap_testpvc.yaml
#进入Pod
kubectl exec -n swgx -it wisemap -- /bin/bash
#创建目录并拷贝包
mkdir -p /opt/test_pvc/swgx/WiseMapGisServer-v6.2.0-28067
cp -Rpf /opt/WiseMapGisServer-v6.2.0-28067/* /opt/test_pvc/swgx/WiseMapGisServer-v6.2.0-28067/
#退出Pod
exit
#删除Pod
kubectl delete pod wisemap -n swgx
```

创建Deployment

创建`wisemap.yaml`并写入如下内容

`wisemap.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wisemap-deployment
  namespace: swgx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wisemap
  template:
    metadata:
      labels:
        app: wisemap
    spec:
      containers:
        - name: wisemapserver
          image: docker.1ms.run/ubuntu:16.04
          env:
            - name: LANG
              value: C.UTF-8
            - name: LC_ALL
              value: C.UTF-8
          command: ["/opt/WiseMapGisServer-v6.2.0-28067/server/bin/mgserver.sh"]
          volumeMounts:
            - name: swgx-ce-pvc
              mountPath: /opt/WiseMapGisServer-v6.2.0-28067
              subPath: swgx/WiseMapGisServer-v6.2.0-28067
        - name: wisemaphttp
          image: docker.1ms.run/ubuntu:16.04
          env:
            - name: LANG
              value: C.UTF-8
            - name: LC_ALL
              value: C.UTF-8
          command:
            [
              "/opt/WiseMapGisServer-v6.2.0-28067/webserverextensions/apache2/bin/apachectl",
            ]
          args: ["-D", "FOREGROUND"]
          ports:
            - containerPort: 8008
          volumeMounts:
            - name: swgx-ce-pvc
              mountPath: /opt/WiseMapGisServer-v6.2.0-28067
              subPath: swgx/WiseMapGisServer-v6.2.0-28067
      volumes:
        - name: swgx-ce-pvc
          persistentVolumeClaim:
            claimName: swgx-ce-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: wisemap-service
  namespace: swgx
spec:
  selector:
    app: wisemap
  ports:
    - port: 8008
      targetPort: 8008
      nodePort: 38008
  type: NodePort
```

应用此yaml即可
