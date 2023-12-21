#!/usr/bin/env bash
#===============================================================================
#
#          FILE: ChatGPT-Next-Web_build.sh
#
#         USAGE: ./ChatGPT-Next-Web_build.sh
#
#   DESCRIPTION: ChatGPT-Next-Web项目一键构建、部署、更新脚本;支持CentOS与Ubuntu
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

INFO1() {
  ${SETCOLOR_SKYBLUE} && echo " $1 "  && ${SETCOLOR_NORMAL}
}

text="注: 国内服务器请选择参数 2"
width=75
padding=$((($width - ${#text}) / 2))



function CHECK_OS() {
if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "无法确定发行版"
    exit 1
fi


# 根据发行版选择存储库类型
case "$ID" in
    "centos")
        repo_type="centos"
        ;;
    "debian")
        repo_type="debian"
        ;;
    "rhel")
        repo_type="rhel"
        ;;
    "ubuntu")
        repo_type="ubuntu"
        ;;
    "opencloudos")
        repo_type="centos"
        ;;
    "rocky")
        repo_type="centos"
        ;;
    *)
        WARN "此脚本暂不支持您的系统: $ID"
        exit 1
        ;;
esac

echo "------------------------------------------"
echo "系统发行版: $NAME"
echo "系统版本: $VERSION"
echo "系统ID: $ID"
echo "系统ID Like: $ID_LIKE"
echo "------------------------------------------"
}

function CHECKFIRE() {
SUCCESS "Firewall && SELinux detection."

# Check if firewall is enabled
systemctl stop firewalld &> /dev/null
systemctl disable firewalld &> /dev/null
systemctl stop iptables &> /dev/null
systemctl disable iptables &> /dev/null
ufw disable &> /dev/null

# Check if SELinux is enforcing
if [[ "$repo_type" == "centos" || "$repo_type" == "rhel" ]]; then
    if sestatus | grep "SELinux status" | grep -q "enabled"; then
        WARN "SELinux is enabled. Disabling SELinux..."
        setenforce 0
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        INFO1 "SELinux is already disabled."
    else
        INFO1 "SELinux is already disabled."
    fi
fi
}

function INSTALL_PACKAGE(){
PACKAGES_APT="lsof jq wget postfix mailutils git"
PACKAGES_YUM="lsof jq wget postfix yum-utils mailx s-nail git"
# 检查命令是否存在
if command -v yum >/dev/null 2>&1; then
    SUCCESS "安装系统必要组件"
    yum -y install $PACKAGES_YUM --skip-broken &>/dev/null
    systemctl restart postfix &>/dev/null
elif command -v apt-get >/dev/null 2>&1; then
    SUCCESS "安装系统必要组件"
    apt-get install -y $PACKAGES_APT --ignore-missing &>/dev/null
    systemctl restart postfix &>/dev/null
else
    WARN "无法确定可用的包管理器"
    exit 1
fi
}


function DL() {
SUCCESS "脚本下载"
printf "%*s\033[31m%s\033[0m%*s\n" $padding "" "$text" $padding ""
SUCCESS "执行完成"

read -e -p "请选择你的服务器网络环境[国外1/国内2]： " NETWORK
if [[ ${NETWORK} == 1 ]];then
    if [[ "$repo_type" = "centos" ]] || [[ "$repo_type" = "rhel" ]]; then
        INFO "《This is $repo_type.》"
        SUCCESS "系统环境检测中，请稍等..."
        bash -c "$(wget -q -O- https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Next-Web/install/ChatGPT-Next-Web_C.sh)"
    elif [[ "$repo_type" == "ubuntu" ]] || [ "$repo_type" == "debian" ]; then
        INFO "《This is $repo_type.》"
        SUCCESS "系统环境检测中，请稍等..."
        systemctl restart systemd-resolved
        bash -c "$(wget -q -O- https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Next-Web/install/ChatGPT-Next-Web_U.sh)"
    else
        echo "Unknown Linux distribution."
        exit 2
    fi
elif [[ ${NETWORK} == 2 ]];then
    if [[ "$repo_type" = "centos" ]] || [[ "$repo_type" = "rhel" ]]; then
        INFO "《This is $repo_type.》"
        SUCCESS "系统环境检测中，请稍等..."
        bash -c "$(wget -q -O- https://mirror.ghproxy.com/https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Next-Web/install/ChatGPT-Next-Web_C.sh)"
    elif [[ "$repo_type" == "ubuntu" ]] || [[ "$repo_type" == "debian" ]]; then
        INFO "《This is $repo_type.》"
        SUCCESS "系统环境检测中，请稍等..."
        systemctl restart systemd-resolved
        bash -c "$(wget -q -O- https://mirror.ghproxy.com/https://raw.githubusercontent.com/dqzboy/chatgpt-web/main/ChatGPT-Next-Web/install/ChatGPT-Next-Web_U.sh)"
    else
        echo "Unknown Linux distribution."
        exit 2
    fi
else
   ERROR "Parameter Error"
fi
}
function main() {
CHECK_OS
CHECKFIRE
INSTALL_PACKAGE
DL
}
main
