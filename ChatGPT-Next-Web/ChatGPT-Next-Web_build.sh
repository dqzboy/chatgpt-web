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
SETCOLOR_YELLOW="echo -en \\E[1;33m"
GREEN="\033[1;32m"
RESET="\033[0m"
PURPLE="\033[35m"


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

WARN() {
  ${SETCOLOR_YELLOW} && echo "$1"  && ${SETCOLOR_NORMAL}
}

text="注: 国内服务器请选择参数 2"
width=75
padding=$((($width - ${#text}) / 2))


function PACKAGE_MANAGER() {
    # 判断使用的包管理工具
    if command -v apt-get &> /dev/null; then
        package_manager="apt-get"
    elif command -v apt &> /dev/null; then
        package_manager="apt"
    else
        ERROR "Unsupported package manager."
        exit 1
    fi
}

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
    $package_manager -y install $PACKAGES_YUM --skip-broken &>/dev/null
    systemctl restart postfix &>/dev/null
elif command -v apt >/dev/null 2>&1; then
    SUCCESS "安装系统必要组件"
    $package_manager install -y $PACKAGES_APT --ignore-missing &>/dev/null
    systemctl restart postfix &>/dev/null
elif command -v apt-get >/dev/null 2>&1; then
    SUCCESS "安装系统必要组件"
    $package_manager install -y $PACKAGES_APT --ignore-missing &>/dev/null
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
PACKAGE_MANAGER
CHECK_OS
CHECKFIRE

while true; do
    read -e -p "$(echo -e ${GREEN}"是否执行软件包安装? [y/n]: "${RESET})" choice_package
    case "$choice_package" in
        y|Y )
            INSTALL_PACKAGE
            break;;
        n|N )
            WARN "跳过软件包安装步骤。"
            break;;
        * )
            echo "请输入 'y' 表示是，或者 'n' 表示否。";;
    esac
done

DL
}
main
