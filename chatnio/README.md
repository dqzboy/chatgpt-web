## 准备工作
🔔 **说明**：目前该脚本采用源码编译部署，非容器化运行(机器规格建议2C/4G)；脚本适用于 CentOS8,9 \ RHEL8,9 \ Rocky8,9 <br>
⚠️  **注意**：***建议使用裸系统运行脚本，脚本里面基础环境都会一键部署完成！*** 如果服务器已经安装了Nginx，那么构建之前请指定前端项目存放的Nginx根路径 <br>
🚀 **更新**：更新版本，只需要再次执行部署脚本即可；注意：更新之后清理浏览器缓存或者无痕模式打开 <br>
> **[TG交流群](https://t.me/+ghs_XDp1vwxkMGU9)**

|:octocat:机场推荐|:link:链接| :pushpin:机场概况
|--|--|--|
|:white_check_mark:魔戒|[:link:官网](https://mojie.me/#/register?code=CG6h8Irm)|按量不限时、不限速、不限设备，解锁ChatGPT
|:white_check_mark:Teacat|[:link:官网](https://teacat.cloud/#/register?code=ps4sZcDa)|按周期、不限速、不限设备、IEPL专线，解锁ChatGPT
|:white_check_mark:八戒|[:link:官网](https://bajie.one/#/register?code=uX4zUk5c)|按量不限时、IEPL专线、不限速、不限设备、低延迟，高网速，解锁ChatGPT|
|:white_check_mark:acyun|[:link:官网](https://yysw.acyun.tk/index.php#/register?code=ZvmLh28A)|按量不限时(3T只需40RMB)、高速中转线路、不限速、不限制客户端数量，解锁ChatGPT|

## 快速开始
执行如下命令一键安装chatnio
```shell
#（1）创建脚本执行目录
mkdir -p /data/chatnio/config && cd /data/chatnio

#（2）下载执行脚本
# CentOS
yum -y install wget curl

#（3）下载 env.example 配置文件；注意执行脚本前先进行修改里面后端地址为你自己的
wget https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/chatnio/env.example

#（4）下载 config.yaml 配置文件到config目录下；无特殊要求不要修改
wget -P config/ https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/chatnio/config.yaml

#（5）执行如下命令一键安装chatnio
# RHEL and CentOS 8/9 or Rocky 8/9
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/chatnio/Install/chatnio_install.sh)"
```

