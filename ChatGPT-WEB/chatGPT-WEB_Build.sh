#!/usr/bin/env bash
#===============================================================================
#
#          FILE: chatGPT-WEB_Build.sh
#
#         USAGE: ./chatGPT-WEB_Build.sh
#
#   DESCRIPTION: chatGPT-WEB项目一键构建、部署脚本;支持CentOS与Ubuntu
#
#  ORGANIZATION: DingQz dqzboy.com
#===============================================================================

SETCOLOR_SKYBLUE="echo -en \\E[1;36m"
SETCOLOR_SUCCESS="echo -en \\E[0;32m"
SETCOLOR_NORMAL="echo  -en \\E[0;39m"
SETCOLOR_RED="echo  -en \\E[0;31m"


SUCCESS() {
  ${SETCOLOR_SUCCESS} && echo "------------------------------------< $1 >-------------------------------------"  && ${SETCOLOR_NORMAL}
}

ERROR() {
  ${SETCOLOR_RED} && echo ">>>>>>>> $1 <<<<<<<<"  && ${SETCOLOR_NORMAL}
}

INFO() {
  ${SETCOLOR_SKYBLUE} && echo "------------------------------------ $1 -------------------------------------"  && ${SETCOLOR_NORMAL}
}

text="注: 国内服务器请选择参数 2"
width=75
padding=$((($width - ${#text}) / 2))


function DL() {
SUCCESS "脚本下载"
printf "%*s\033[31m%s\033[0m%*s\n" $padding "" "$text" $padding ""
SUCCESS "执行完成"

read -e -p "请选择你的服务器网络环境[国外1/国内2]： " NETWORK
if [[ ${NETWORK} == 1 ]];then
    if [ -f /etc/redhat-release ]; then
        INFO "《This is CentOS.》"
        SUCCESS "系统环境检测中，请稍等..."
        bash -c "$(wget -q -O- https://raw.githubusercontent.com/dqzboy/ShellProject/main/ChatGPT/ChatGPT-WEB/chatGPT-WEB_C.sh)"
    elif [ -f /etc/lsb-release ]; then
        if grep -q "DISTRIB_ID=Ubuntu" /etc/lsb-release; then
            INFO "《This is Ubuntu.》"
            SUCCESS "系统环境检测中，请稍等..."
            systemctl restart systemd-resolved
            bash -c "$(wget -q -O- https://raw.githubusercontent.com/dqzboy/ShellProject/main/ChatGPT/ChatGPT-WEB/chatGPT-WEB_U.sh)"
        else
            echo "Unknown Linux distribution."
            exit 1
        fi
    else
        echo "Unknown Linux distribution."
        exit 2
    fi
elif [[ ${NETWORK} == 2 ]];then
        if [ -f /etc/redhat-release ]; then
        INFO "《This is CentOS.》"
        SUCCESS "系统环境检测中，请稍等..."
        bash -c "$(wget -q -O- https://ghproxy.com/https://raw.githubusercontent.com/dqzboy/ShellProject/main/ChatGPT/ChatGPT-WEB/chatGPT-WEB_C.sh)"
    elif [ -f /etc/lsb-release ]; then
        if grep -q "DISTRIB_ID=Ubuntu" /etc/lsb-release; then
            INFO "《This is Ubuntu.》"
            SUCCESS "系统环境检测中，请稍等..."
            systemctl restart systemd-resolved
            bash -c "$(wget -q -O- https://ghproxy.com/https://raw.githubusercontent.com/dqzboy/ShellProject/main/ChatGPT/ChatGPT-WEB/chatGPT-WEB_U.sh)"
        else
            echo "Unknown Linux distribution."
            exit 1
        fi
    else
        echo "Unknown Linux distribution."
        exit 2
    fi
else
   ERROR "Parameter Error"
fi
}
DL
