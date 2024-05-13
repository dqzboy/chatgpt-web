<div style="text-align: center"></div>
  <p align="center">
  <img src="https://user-images.githubusercontent.com/42825450/233398049-0456e5f8-c36e-42fa-a933-2fb640bdf714.png" width="100px" height="100px">
      <br>
      <i>One-click deployment of your ChatGPT site.</i>
  </p>
</div>

> Use this script to quickly create your own ChatGPT web site. | 使用此脚本可以快速创建您自己的 ChatGPT 网站。

[Telegram Group](https://t.me/+ghs_XDp1vwxkMGU9) 
<details>
<summary>Click here to join the WeChat group</summary>
<div align="center">
<img src="https://github.com/dqzboy/ChatGPT-Proxy/assets/42825450/09211fb0-70bd-4ac7-bb99-2ead29561142" width="400px">
</div>
</details>

|:octocat:机场推荐|:link:链接| :pushpin:机场概况
|--|--|--|
|:white_check_mark:魔戒|[:link:官网](https://mojie.me/#/register?code=CG6h8Irm)|按量不限时、不限速、不限设备，解锁ChatGPT
|:white_check_mark:Teacat|[:link:官网](https://teacat.cloud/#/register?code=ps4sZcDa)|按周期、不限速、不限设备、IEPL专线，解锁ChatGPT
|:white_check_mark:八戒|[:link:官网](https://bajie.one/#/register?code=uX4zUk5c)|按量不限时、IEPL专线、不限速、不限设备、低延迟，高网速，解锁ChatGPT|
|:white_check_mark:acyun|[:link:官网](https://acyud.yydsii.com/index.php#/register?code=ZvmLh28A)|按量不限时(3T只需40RMB)、高速中转线路、不限速、不限制客户端数量，解锁ChatGPT|

<div align="center">
<img src="https://camo.githubusercontent.com/82291b0fe831bfc6781e07fc5090cbd0a8b912bb8b8d4fec0696c881834f81ac/68747470733a2f2f70726f626f742e6d656469612f394575424971676170492e676966"
width="2000"  height="3">
</div>

## 📦 部署 | Deployment
### ✨ [ChatGPT-Next-Web](ChatGPT-Next-Web/README.md)
```shell
#（1）创建脚本执行目录
mkdir -p /data/chatgpt-next-web && cd /data/chatgpt-next-web

#（2）下载主执行脚本 ChatGPT-Next-Web_build.sh 脚本会判断当前系统是Ubuntu还是CentOS，其他系统则不会执行构建
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Next-Web/ChatGPT-Next-Web_build.sh)"
```

### ✨ [ChatGPT-Web](ChatGPT-Web-Admin/README.md)
执行如下命令一键安装chatgpt-web
#### Kerwin1202/chatgpt-web
```shell
#（1）创建脚本执行目录
mkdir -p /data/chatgpt-web && cd /data/chatgpt-web

#（2）下载执行脚本
# CentOS
yum -y install wget curl
# ubuntu
apt -y install wget curl

#（3）下载 env.example 配置文件；注意执行脚本前先进行修改里面的内容
wget -O env.example https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Web-Admin/Kerwin1202_env.example

# RHEL and CentOS or Rocky 7/8/9
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Web-Admin/install/ChatGPT-Web-Admin.sh)"

# Ubuntu or Debian
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Web-Admin/install/ChatGPT-Web-Admin_U.sh)"
```

#### Chanzhaoyu/chatgpt-web
```shell
#（1）创建脚本执行目录
mkdir -p /data/chatgpt-web && cd /data/chatgpt-web

#（2）下载执行脚本
# CentOS
yum -y install wget curl
# ubuntu
apt -y install wget curl

#（3）下载 env.example 配置文件；注意执行脚本前先进行修改里面的内容
wget -O env.example https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Web-Admin/Chanzhaoyu_env.example

# RHEL and CentOS or Rocky 7/8/9
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Web-Admin/install/ChatGPT-Web-Admin.sh)"

# Ubuntu or Debian
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Web-Admin/install/ChatGPT-Web-Admin_U.sh)"
```
### ✨ [Chat Nio](chatnio/README.md)
```shell
#（1）创建脚本执行目录
mkdir -p /data/chatnio/config && cd /data/chatnio

#（2）下载执行脚本
# CentOS
yum -y install wget curl

#（3）下载 env.example 配置文件；注意执行脚本前先进行修改里面后端地址为你自己的（非分布式部署则无需修改）
wget https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/chatnio/env.example

#（4）下载 config.yaml 配置文件到config目录下；无特殊要求不要修改
wget -P config/ https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/chatnio/config.yaml

#（5）执行如下命令一键安装chatnio
# RHEL and CentOS 8/9 or Rocky 8/9
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/chatnio/Install/ChatNio_Install.sh)"
```

## 🔨 功能 | Functionality
<details>
  <summary><b> 源代码本地一键编译部署 | One-click compile and deploy of source code locally. </b></summary>
</details>

<details>
  <summary><b> 交互式自定义个人信息、代理等 | Interactive customization of personal information, proxies, etc. </b></summary>
</details>

<details>
  <summary><b> 自动检查系统环境，一键部署基础环境 | Automatically check system environment and deploy basic environment with one click </b></summary>
</details>

<details>
  <summary><b> 支持一键部署、一键更新 | Supports one-click deployment and update </b></summary>
</details>

<details>
  <summary><b> 支持主流Linux发行版操作系统 | Supports mainstream Linux distribution operating systems </b></summary>
</details>

<details>
  <summary><b> 支持一键快速卸载 | Supports one-click fast uninstallation</b></summary>
</details>

## 📚 截图 | Screenshot
<br/>
<table>
    <tr>
      <td width="50%" align="center"><b>所需组件检测</b></td>
      <td width="50%" align="center"><b>交互定义信息</b></td>
    </tr>
    <tr>
        <td width="50%" align="center"><img src="https://github.com/dqzboy/chatgpt-web/assets/42825450/7293db62-a284-48b1-b193-0c98af099943?raw=true"></td>
        <td width="50%" align="center"><img src="https://github.com/dqzboy/chatgpt-web/assets/42825450/426aaa15-11c6-432b-9473-36fbde59a31c?raw=true"></td>
    </tr>
    <tr>
      <td width="50%" align="center"><b>OS组件环境检测</b></td>
      <td width="50%" align="center"><b>自定义网站目录</b></td>
    </tr>
        <td width="50%" align="center"><img src="https://github.com/dqzboy/chatgpt-web/assets/42825450/626ba006-4753-413d-a155-c2896ab95506?raw=true"></td>
        <td width="50%" align="center"><img src="https://github.com/dqzboy/chatgpt-web/assets/42825450/1848fb65-ddc7-487f-8f2e-c50d7edef039?raw=true"></td>
    <tr>
    </tr>
    <tr>
      <td width="50%" align="center"><b>ChatGPT-Next-WEB</b></td>
      <td width="50%" align="center"><b>ChatGPT-WEB</b></td>
    </tr>
        <td width="50%" align="center"><img src="https://user-images.githubusercontent.com/42825450/232282806-5dbf4bae-34bc-4371-8aad-bfc4df999681.png?raw=true"></td>
        <td width="50%" align="center"><img src="https://user-images.githubusercontent.com/42825450/226398855-7e914763-5204-423b-be14-a8cc7a9c85a0.png?raw=true"></td>
    <tr>
    </tr>
</table>
