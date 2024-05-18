## 脚本执行流程演示
🔔 **说明**：脚本适用于CentOS 7、Ubuntu系统、RHEL-8 and CentOS-8 <br>
🚀 **更新**：更新ChatGPT-Next-Web版本，只需要再次执行部署脚本即可，注意：更新之后强刷浏览器或者无痕模式打开查看效果

|:octocat:机场推荐|:link:链接| :pushpin:机场概况
|--|--|--|
|:white_check_mark:赔钱机场|[:link:官网](https://www.xn--mes358aby2apfg.site/#/register?code=hsJRRcIk)|按量不限时、不限速、电信移动联通高质量线路、不限客户端数量、全网高性价比机场、解锁奈菲，迪士尼，TikTok，ChatGPT
|:white_check_mark:魔戒|[:link:官网](https://mojie.me/#/register?code=CG6h8Irm)|按量不限时、不限速、不限设备，解锁ChatGPT
|:white_check_mark:Teacat|[:link:官网](https://teacat.cloud/#/register?code=ps4sZcDa)|按周期、不限速、不限设备、IEPL专线，解锁ChatGPT
|:white_check_mark:八戒|[:link:官网](https://bajie.one/#/register?code=uX4zUk5c)|按量不限时、IEPL专线、不限速、不限设备、低延迟，高网速，解锁ChatGPT|
|:white_check_mark:acyun|[:link:官网](https://yysw.acyun.tk/index.php#/register?code=ZvmLh28A)|按量不限时(3T只需40RMB)、高速中转线路、不限速、不限制客户端数量，解锁ChatGPT|

```shell
#（1）创建脚本执行目录
mkdir -p /data/chatgpt-next-web && cd /data/chatgpt-next-web

#（2）下载主执行脚本 ChatGPT-Next-Web_build.sh 脚本会判断当前系统是Ubuntu还是CentOS，其他系统则不会执行构建
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Next-Web/ChatGPT-Next-Web_build.sh)"
```
<table>
    <tr>
        <td width="50%" align="center"><img src="https://user-images.githubusercontent.com/42825450/232283480-2fe73cc9-32d9-49eb-bb3f-c58caec74b59.png"?raw=true"></td>
    </tr>
</table>
     
<table>
    <tr>
        <td width="50%" align="center"><img src="https://user-images.githubusercontent.com/42825450/232283587-36338ca5-fbce-460d-8b6f-f805bf42ba30.png"?raw=true"></td>
    </tr>
</table>

<table>
    <tr>
        <td width="50%" align="center"><img src="https://user-images.githubusercontent.com/42825450/232283604-8c9833b9-52d0-4a87-adc8-a8615ada6a58.png"?raw=true"></td>
    </tr>
</table>



## 部署完成访问
![image](https://user-images.githubusercontent.com/42825450/232282806-5dbf4bae-34bc-4371-8aad-bfc4df999681.png)


## 一键卸载
- 运行一键卸载脚本，会将安装脚本中所安装的Nodejs组件一键卸载
- 注意：如果你手动安装了其他版本，则需要使用适当的命令来卸载它们
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dqzboy/ChatGPT/main/ChatGPT-Next-Web/uninstall/uninstall.sh)"
```
