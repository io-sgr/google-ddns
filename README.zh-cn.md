# 利用 Google Cloud DNS 实现 DDNS

*使用其它语言阅读: [English](README.md), [简体中文](README.zh-cn.md).*

## 背景

随着智能家居设备的推广和普及，越来越多的人希望能够在自己不在家的时候依然能够访问或者控制家中的设备，比如说我家中有一个 NAS 服务器，而我出门在外的时候依然可以访问到 NAS 的管理界面甚至是以一种安全的方式直接访问上面的文件。如果你知道自己家里网络的公网 IP，外加端口映射，你是可以直接访问家中的设备的，然而问题是大部分人都是使用 PPPoE 来拨号上网，大部分网络提供商并不会给你一个固定的 IPv4 地址，动态分配的地址随时有可能发生变化，通常是一周左右。

比较常见的解决方式是通过动态域名解析，也就是 Dynamic DNS（DDNS），而且现在主流路由器基本都内置了对 DDNS 的支持，也有很多知名的 DDNS 服务提供商，他们会帮你在某个特定域名下创建属于你自己的子域名，然后帮你动态绑定一条 A 记录到你目前的公网 IP（需要在路由器里做协同配置），其中有一些服务提供商甚至提供免费的 DDNS 服务，但需要你定期更新延长租期。

如果你觉得他们提供的域名都太丑，而且不支持多级的子域名之类，想使用自己的域名换取更高的灵活度，那事情有些许的不同。你显然可以继续搭配 DDNS 使用，你所需要做的仅仅是创建一条 CNAME 记录指向 DDNS 服务提供商的子域名，但这么做的问题是，如果其他人用 `nslookup` 之类的命令来查询你的域名解析记录，这个子域名就会被暴露在结果中。

为了避免这种情况，我更倾向于用另一种方式来自动的更新我某个域名的 A 记录，于是就有了这个基于 Google Cloud DNS 的项目。

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
    -e PROXY_TYPE=<type of proxy, http or socks5 for instance> \
    -e PROXY_ADDR=<IP address or hostname of proxy> \
    -e PROXY_PORT=<Port of proxy> \
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
