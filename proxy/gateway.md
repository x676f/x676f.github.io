# 搭建自动分流的透明代理网关

适用 CN 墙内，使以下形式共存：

- 自动分流网关：DHCP 自动分配，或手动指定
- `socks5 代理`
- `socks5 代理` 自动分流
- `HTTP 代理`
- `HTTP 代理` 自动分流


## 要实现的自动分流

- 代理：其它 DNS 解析和访问流量
- 直连：局域网流量
- 直连：墙内 DNS 解析和访问流量
- 直连：BT 流量
- 拦截：广告流量


## 已有 2 个机场

- 日用机场 [ShadowsocksR] 协议的 IPLC 专线
- 备用机场 [vmess] 协议的 BGP 多线


## 准备工作

- ubuntu 20.04 LTS


## 思路

- [v2ray] 和 [ShadowsocksR] 协作
- [privoxy] 辅助，可无

### 使 v2ray 兼容 ShadowsocksR

想要把临近自己城市的 IPLC 专线作为默认代理，然鹅 [v2ray] 并不直接兼容 SSR 协议，所以：

- 独立运行 [ShadowsocksR] 实现 `socks5` 代理，监听在端口 `1080` 上
- 同时运行 [privoxy] 实现 `HTTP` 代理，监听在端口 `8080` 上，转发给 `1080` 的 `socks5`

这样，在任何软件里配置 socks5 或 HTTP 代理，就都可以工作了。

> 1080 和 8080 都走代理，不分流

然后把 `1080` 的 `socks5` 提供给 [v2ray] 作为一个 `outbound`，就解决了由 [v2ray] 向 [ShadowsocksR] 的兼容。


### 使用 v2ray作为枢纽，实现自动分流和网关

[v2ray] 定义 3 个 `inbound` 入口

- [dokodemo-door] 任意门，由 `tproxy` 为网关流量提供服务
- `socks` 在 1081 端口提供 `socks5 代理` 服务，自动分流
- `http` 在 8081 端口提供 `HTTP 代理` 服务，自动分流


[v2ray] 定义 4 个 `outbound` 出口，分别标记为：

- **proxy**<br>
  交给 `socks` 协议的 `1080` 端口
- **direct**<br>
  直连
- **block**<br>
  交给 `blackhole` 黑洞拦截
- **dns-out**<br>
  交给 `DNS` 查询


[v2ray] 的内部路由

- 53 端口传入的 UDP 流量交给 `dns-out` 进行 DNS 查询
- 123 端口的 UDP 交给 `direct` 直连
- `223.5.5.5` 和 `114.114.114.114` 是大陆的两个 DNS 服务器 IP 交给 `direct` 直连
- `8.8.8.8` 和 `1.1.1.1` 是 Google 和 Cloudflare 的 DNS 服务器 IP 交给 `proxy` 代理
- [v2ray] 提供的 `geosite` 和 [ToutyRater] 提供的 `ext:h2y.dat` 识别广告域名，交给 `block` 拦截
- `BT 流量` 交给 `direct` 直连
- [v2ray] 提供的 `geoip` 把 `private` 私网和 `cn` 大陆 IP 交给 `direct` 直连
- [v2ray] 提供的 `geosite` 把 `cn` 大陆域名交给 `direct` 直连


## 配置文件

下载配置文件，并编辑

```console
$ sudo wget https://github.com/ToutyRater/V2Ray-SiteDAT/raw/master/geofiles/h2y.dat /usr/bin/v2ray/h2y.dat
$ sudo wget https://github.com/x676f/x676f.github.io/raw/proxy/shadowsocksr/config.json /etc/shadowsocksr/config.json
$ sudo nano /etc/shadowsocksr/config.json
$ sudo wget https://github.com/x676f/x676f.github.io/raw//proxy/v2ray/config.json /etc/v2ray/config.json
$ sudo nano /etc/v2ray/config.json
```

- [ShadowsocksR] 的配置文件 `/etc/shadowsocksr/config.json` 记得改成自己的代理配置
- [v2ray] 的配置文件 `/etc/v2ray/config.json` 第 182 行，换成代理的根域名，以确保由网关通往代理的流量不会死循环在网关本机


## 系统服务

### 定义

```console
$ sudo wget https://github.com/x676f/x676f.github.io/raw/proxy/service/shadowsocksr.service /etc/systemd/system/shadowsocksr.service
$ sudo wget https://github.com/x676f/x676f.github.io/raw/proxy/service/v2ray.service /etc/systemd/system/v2ray.service
```

### 启动

```console
$ sudo systemctl enable shadowsocksr
$ sudo systemctl enable v2ray
```

### 查看状态

```console
$ sudo service shadowsocksr status
$ sudo service v2ray status
```

### 重启

```console
$ sudo service shadowsocksr restart
$ sudo service v2ray restart
```

---
> 至此，1080, 1081, 8080, 8081 都已可用
---

## 系统 iptables 规则

下载规则脚本并执行

```console
$ cd ~
$ wget https://github.com/x676f/x676f.github.io/raw/proxy/bash/tproxy.sh
$ sudo chmod +x ./tproxy.sh
$ sudo ./tproxy.sh
```

保存规则文件

```console
$ sudo iptables-save > /etc/iptables.v4
```

确保每次重启时自动载入规则

```console
$ sudo wget https://github.com/x676f/x676f.github.io/raw/proxy/service/shadowsocksr.service /etc/systemd/system/load-iptables.service
$ sudo systemctl enable load-iptables
```

---
> 至此，网关已可用
---

## THE END

手工重启，验证所有服务都可以自动加载

```console
$ sudo reboot
```

本篇完结


[v2ray]: https://www.v2ray.com
[dokodemo-door]: https://www.v2ray.com/chapter_02/protocols/dokodemo.html
[vmess]: https://www.v2ray.com/chapter_02/protocols/vmess.html
[ShadowsocksR]: https://github.com/shadowsocksrr/shadowsocksr
[privoxy]: https://www.privoxy.org/
[ToutyRater]: https://github.com/ToutyRater
