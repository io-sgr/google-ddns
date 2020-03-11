# 利用 Google Cloud DNS 实现 DDNS

*使用其它语言阅读: [English](README.md), [简体中文](README.zh-cn.md).*

## 背景

It's a pretty common requirement for the folks who want to host some service at their home and expose it to the public network, for example I have a NAS at home and would like to access the admin UI remotely. I use PPPoE to connect to the public Internet, and my ISP usually won't give me a static IPv4 address, they will constantly renew it like weekly or whenever they wish to.

Most of modern routers now have build-in support for DDNS, and we have lots of well-known service providers, some of them even have free-tier product but requires a constant renew every month.

If you've already got your own domain name(like me) and prefer to reuse it, things could be a little bit different. Obviously you can continue to use DDNS products, and create a CNAME record point to the hostname supplied by DDNS service provider, but when people do a `nslookup`, that hostname will be exposed in the result.

To avoid that, I'm more preferred use my own way to update A record automatically when IP changes been detected. Here comes my Google Cloud DNS based solution.

## 准备工作
* 一个托管在 [Google Cloud Platform](https://cloud.google.com/) 的项目。
* 你的 DNS 记录是通过 Google Cloud DNS 来管理的。
* 你的本地可以运行 [Docker](https://www.docker.com)。

## 如何搭建

### 创建服务账户
1. 登录 [Google Cloud Console](https://console.cloud.google.com/)
2. 进入 **IAM & Admin** -> **Roles**
3. 创建一个名叫 **DDNS Client** 的角色，并给予下列权限：
   * dns.changes.create
   * dns.changes.get
   * dns.changes.list
   * dns.dnsKeys.get
   * dns.dnsKeys.list
   * dns.managedZoneOperations.get
   * dns.managedZoneOperations.list
   * dns.managedZones.get
   * dns.managedZones.list
   * dns.managedZones.update
   * dns.projects.get
   * dns.resourceRecordSets.create
   * dns.resourceRecordSets.delete
   * dns.resourceRecordSets.list
   * dns.resourceRecordSets.update
   * resourcemanager.projects.get
4. 进入 **IAM & Admin** -> **Service Accounts**
5. 点击顶部的 **+ CREATE SERVICE ACCOUNT** 按钮，给你的服务账户起一个容易识别的名字，例如 `ddns-client`。
6. 点击 **CREATE** 按钮。
7. 使用 **Select a role** 旁边的下拉菜单来选择刚刚建立的角色。
8. 点击 **CONTINUE** 按钮。
9. 点击 **+ CREATE KEY**，选择 **JSON** 类型（这个应该是默认选项），然后点击 **CREATE** 按钮，这时应该会自动下载一个文件，把它安全的保存起来，我们稍后会用到。
10. 点击 **DONE** 按钮，这是你应该会被重定向回服务账户列表页面，在这里你可以检查刚刚创建的服务账户。

### 启动客户端
```sh
docker run -d --restart=unless-stopped \
    --name=google-ddns \
    -e ZONE=<your zone name> \
    -e DOMAIN_NAME=<your domain name> \
    -v <path to json file>:/credential \
    sgrio/google-ddns
```

上面的命令是一个示例，你需要把其中的 `<your zone name>`, `<your domain name>` and `<path to json file>` 替换成实际的值。

我个人建议不要直接使用顶级域名，用一个子域名来连接你的内网，比如 `home.example.com` 。

### 搞定！

你的公网 IP 应该会在五分钟左右更新到 Google Cloud DNS。

## 异常诊断
* 你可以通过下面的命令查看 Docker 容器的日志
```sh
docker logs -f goodle-ddns
```
