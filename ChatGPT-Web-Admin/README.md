## 准备工作
- **说明**：目前该脚本采用源码编译部署，非容器化运行(内存建议2G+)；目前脚本适用于CentOS 7\RHEL8,9\Rocky8,9\CentOS-8\Ubuntu\Debian
- **重要**：目前脚本主要部署的项目为：[Kerwin1202/chatgpt-web](https://github.com/Kerwin1202/chatgpt-web) 跟 [Chanzhaoyu/chatgpt-web](https://github.com/Chanzhaoyu/chatgpt-web) ；前者带用户管理，多KEY轮询等，后者无。所以env配置也有区别，部署前请根据自己要部署的项目下载本仓库下面的`env.example`配置文件到你运行脚本的目录下
- **注意**：***建议使用裸系统运行脚本，脚本里面基础环境都会一键部署完成！*** 如果服务器已经安装了Nginx，那么构建之前请指定ChatGPT-WEB前端项目存放的Nginx根路径
- **版本更新**：更新chatGPT-web版本，只需要再次执行部署脚本即可，`env`文件无需变更；注意：更新之后强刷浏览器或者无痕模式打开
- **机场推荐**：[机场1按量不限时，解锁ChatGPT](https://mojie.mx/#/register?code=CG6h8Irm) \ [机场2按周期，解锁ChatGPT](https://teacat.cloud/#/register?code=ps4sZcDa) \ [专线机场,不限时不限速不限设备](https://bajie.one/#/register?code=uX4zUk5c)

```shell
#（1）创建脚本执行目录
mkdir -p /data/chatgpt-web && cd /data/chatgpt-web

#（2）下载执行脚本
# CentOS
yum -y install wget
# ubuntu
apt -y install wget

#（3）下载对应的env.example配置文件；注意执行脚本前先进行修改里面的内容
【Kerwin1202/chatgpt-web】
wget  -O env.example https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Web-Admin/Kerwin1202_env.example

【Chanzhaoyu/chatgpt-web】
wget  -O env.example https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Web-Admin/Chanzhaoyu_env.example

# CentOS 7 or CentOS-8
bash -c "$(wget -q -O- https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Web-Admin/install/ChatGPT-Web-Admin_C.sh)"

# RHEL-8/9 or Rocky-8/9
bash -c "$(wget -q -O- https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Web-Admin/install/ChatGPT-Web-Admin_R.sh)"

# Ubuntu or Debian
bash -c "$(wget -q -O- https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Web-Admin/install/ChatGPT-Web-Admin_U.sh)"
```

## 执行过程
<img src="https://user-images.githubusercontent.com/42825450/236674720-f332c732-7be5-4517-8a9c-d8ea00b7d6d4.gif" width="1000px">
<img src="https://user-images.githubusercontent.com/42825450/236674847-0c726d2e-9cd2-4624-8081-d8ab4b204025.png" width="1000px">

## Nginx后端配置参考
- 需要在server块中添加一个location规则用来代理后端API接口地址，配置修改参考如下：

> /etc/nginx/conf.d/default.conf
```shell
server {
    listen       80;
    server_name  localhost;

    #access_log  /var/log/nginx/host.access.log  main;

    #禁止境内常见爬虫(根据需求自行控制是否禁止)
    if ($http_user_agent ~* "qihoobot|Yahoo! Slurp China|Baiduspider|Baiduspider-image|spider|Sogou spider|Sogou web spider|Sogou inst spider|Sogou spider2|Sogou blog|Sogou News Spider|Sogou Orion spider|ChinasoSpider|Sosospider|YoudaoBot|yisouspider|EasouSpider|Tomato Bot|Scooter") {
        return 403;
    }

    #禁止境外常见爬虫(根据需求自行控制是否禁止)
    if ($http_user_agent ~* "Googlebot|Googlebot-Mobile|AdsBot-Google|Googlebot-Image|Mediapartners-Google|Adsbot-Google|Feedfetcher-Google|Yahoo! Slurp|MSNBot|Catall Spider|ArchitextSpider|AcoiRobot|Applebot|Bingbot|Discordbot|Twitterbot|facebookexternalhit|ia_archiver|LinkedInBot|Naverbot|Pinterestbot|seznambot|Slurp|teoma|TelegramBot|Yandex|Yeti|Infoseek|Lycos|Gulliver|Fast|Grabber") {
        return 403;
    }

    #禁止指定 UA 及 UA 为空的访问
    if ($http_user_agent ~ "WinHttp|WebZIP|FetchURL|node-superagent|java/|Bytespider|FeedDemon|Jullo|JikeSpider|Indy Library|Alexa Toolbar|AskTbFXTV|AhrefsBot|CrawlDaddy|CoolpadWebkit|Java|Feedly|Apache-HttpAsyncClient|UniversalFeedParser|ApacheBench|Microsoft URL Control|Swiftbot|ZmEu|oBot|jaunty|Python-urllib|lightDeckReports Bot|YYSpider|DigExt|HttpClient|MJ12bot|heritrix|Ezooms|BOT/0.1|YandexBot|FlightDeckReports|Linguee Bot|iaskspider|^$") {
        return 403;
    }

    #禁止非 GET|HEAD|POST 方式的抓取
    if ($request_method !~ ^(GET|HEAD|POST)$) {
        return 403;
    }

    #禁止 Scrapy 等工具的抓取
    if ($http_user_agent ~* (Scrapy|HttpClient)) {
        return 403;
    }

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    location /api/ {
        # 处理 Node.js 后端 API 的请求
        proxy_pass http://localhost:3002;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;        
        proxy_buffering off;
        proxy_redirect off;
    }
}
```
- 添加配置后，重载配置
```shell
nginx -t
nginx -s reload
```

## 常见问题总结
### 问题1：500 错误
#### 问题描述
> 部署 Kerwin1202/chatgpt-web 项目之后，访问页面提示500
#### 问题原因
- 1、Nginx配置错误，反代后端服务无效（一般为自己搭建的Nginx服务，使用脚本一建配置的Nginx没问题）
- 2、后端服务未启动或者启动之后端口未监听等
- 3、Mongo 配置了错误的用户或密码；创建的用户和密码不要有特殊字符
#### 问题解决
- 可以查看Nginx日志来判断是否是Nginx配置问题
- 检查后端服务是否运行正常，或端口(默认3002)是否监听
- env里面配置的mongodb的URL、账号、密码是否正确；**如果Nginx日志没有报错，那大概率是这个原因导致**

### 问题2：构建失败或报错
#### 问题描述
> 通过脚本部署项目，构建阶段报错，无法继续构建

#### 问题原因
- （1）基础环境问题，相关组件安装失败或者组件版本不兼容导致
- （2）由于是源码编译部署，服务器资源规格太小，例如1C1G的机器，编译过程没有充足的内存进行编译

#### 问题解决
- 1、检查组件是否正确安装，可以根据编译时终端显示的日志确认具体问题
- 2、机器内存如果小于等于1G，建议内存给大点，起码2G+；或者在大内存的机器进行构建，然后把构建好的制品打包上传到小规格的机器上也可以。

## 推荐阅读文章
[国内服务器实现科学上网并接入chatGPT-WEB](https://www.dqzboy.com/13754.html) 

