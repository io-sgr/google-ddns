# DDNS Client using Google Cloud DNS

*Read this in other languages: [English](README.md), [简体中文](README.zh-cn.md).*

## Background

It's a pretty common requirement for the folks who want to host some service at their home and expose it to the public network, for example I have a NAS at home and would like to access the admin UI remotely. I use PPPoE to connect to the public Internet, and my ISP usually won't give me a static IPv4 address, they will constantly renew it like weekly or whenever they wish to.

Most of modern routers now have build-in support for DDNS, and we have lots of well-known service providers, some of them even have free-tier product but requires a constant renew every month.

If you've already got your own domain name(like me) and prefer to reuse it, things could be a little bit different. Obviously you can continue to use DDNS products, and create a CNAME record point to the hostname supplied by DDNS service provider, but when people do a `nslookup`, that hostname will be exposed in the result.

To avoid that, I'm more preferred use my own way to update A record automatically when IP changes been detected. Here comes my Google Cloud DNS based solution.

## Prerequisites
* You have a project hosted in [Google Cloud Platform](https://cloud.google.com/).
* The DNS record sets of your domain are managed in Google Cloud DNS.
* You can run [Docker](https://www.docker.com) in your local environment.

## How-To

### Create an service account with limited permissions
1. Sign-in to [Google Cloud Console](https://console.cloud.google.com/)
2. Go to **IAM & Admin** -> **Roles**
3. Create a new role named **DDNS Client** for example with the following permissions
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
4. Go to **IAM & Admin** -> **Service Accounts**
5. Click the **+ CREATE SERVICE ACCOUNT** button on the top, give it a reasonable name like `ddns-client`.
6. Click **CREATE** button.
7. Use the drop down menu next to **Select a role** to pickup the role we just created.
8. Click **CONTINUE** button.
9. Click **+ CREATE KEY**, use **JSON** as type which should be default, then click the **CREATE** button, then you should be able to save the key file, store it securely, and we're going to need it later.
10. Click **DONE** button, then you will be redirected back to the service account list.

### Spin up the client
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

Please be sure you've replaced `<your zone name>`, `<your domain name>` and `<path to json file>` in above command to actual values.

I'm more prefer to use a sub-domain like `home.example.com` instead of go with top level domain name.

### You're all set!

You should be able see the record been created within 5 mins.

## Troubleshooting
* You can use the following command to view logs from Docker container.
```sh
docker logs -f goodle-ddns
```
