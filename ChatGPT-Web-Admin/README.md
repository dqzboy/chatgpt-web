## 脚本执行流程演示
- **说明**：目前该脚本采用源码编译部署，非容器化运行；目前脚本适用于CentOS 7、RHEL-8 and CentOS-8
- **重要**：目前脚本主要部署的项目为：[Kerwin1202/chatgpt-web](https://github.com/Kerwin1202/chatgpt-web) 跟 [Chanzhaoyu/chatgpt-web](https://github.com/Chanzhaoyu/chatgpt-web) ；前者带用户中心，后者无。所以env配置也有区别，部署前请根据自己要部署的项目下载本仓库下面的`env.example`配置文件到你运行脚本的目录下
- **注意**：如果服务器已经安装了Nginx，那么构建之前请指定ChatGPT-WEB前端项目存放的Nginx根路径
- **版本更新**：更新chatGPT-web版本，只需要再次执行部署脚本即可，`env`文件无需变更；注意：更新之后强刷浏览器或者无痕模式打开
- **目前个人使用的机场**：[机场1按量不限时，解锁ChatGPT](https://mojie.la/#/register?code=CG6h8Irm) \ [机场2按周期，解锁ChatGPT](https://teacat.cloud/#/register?code=ps4sZcDa) \ [机场3按量不限时，最便宜40/3T](https://yysw.acyun.tk/#/register?code=ZvmLh28A)
```shell
#（1）创建脚本执行目录
mkdir -p /data/chatgpt-web && cd /data/chatgpt-web

#（2）下载执行脚本
# CentOS
yum -y install wget

# CentOS 7 or RHEL-8 and CentOS-8
wget https://raw.githubusercontent.com/dqzboy/ChatGPT/main/ChatGPT-WEB/env.example
bash -c "$(wget -q -O- https://raw.githubusercontent.com/dqzboy/ChatGPT/main/ChatGPT-WEB/chatGPT-WEB_Build.sh)"

# 下载对应的env.example配置文件；注意执行脚本前先进行修改里面的内容
## Kerwin1202/chatgpt-web
wget  -O env.example https://raw.githubusercontent.com/dqzboy/ChatGPT/main/ChatGPT-Web-Admin/Kerwin1202_env.example

## Chanzhaoyu/chatgpt-web
wget  -O env.example https://raw.githubusercontent.com/dqzboy/ChatGPT/main/ChatGPT-Web-Admin/Chanzhaoyu_env.example
```

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
        proxy_set_header X-Nginx-Proxy true;
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


## 推荐阅读文章
[国内服务器实现科学上网并接入chatGPT-WEB](https://www.dqzboy.com/13754.html) 

