#!/usr/bin/env bash
#===============================================================================
#
#          FILE: ChatGPT-Web-Admin_U.sh
# 
#         USAGE: ./ChatGPT-Web-Admin_U.sh
#
#   DESCRIPTION: chatGPT-WEB项目一键构建、部署脚本
# 
#  ORGANIZATION: DingQz dqzboy.com 浅时光博客
#===============================================================================

echo
cat << EOF

          ██████╗██╗  ██╗ █████╗ ████████╗ ██████╗ ██████╗ ████████╗    ██╗    ██╗███████╗██████╗ 
         ██╔════╝██║  ██║██╔══██╗╚══██╔══╝██╔════╝ ██╔══██╗╚══██╔══╝    ██║    ██║██╔════╝██╔══██╗
         ██║     ███████║███████║   ██║   ██║  ███╗██████╔╝   ██║       ██║ █╗ ██║█████╗  ██████╔╝
         ██║     ██╔══██║██╔══██║   ██║   ██║   ██║██╔═══╝    ██║       ██║███╗██║██╔══╝  ██╔══██╗
         ╚██████╗██║  ██║██║  ██║   ██║   ╚██████╔╝██║        ██║       ╚███╔███╔╝███████╗██████╔╝
          ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝        ╚═╝        ╚══╝╚══╝ ╚══════╝╚═════╝                                                                                         
                                                                                         
EOF

echo "----------------------------------------------------------------------------------------------------------"
echo -e "\033[32m机场推荐\033[0m(\033[34m按量不限时，解锁ChatGPT\033[0m)：\033[34;4mhttps://mojie.mx/#/register?code=CG6h8Irm\033[0m"
echo "----------------------------------------------------------------------------------------------------------"
echo
echo

GREEN="\033[0;32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

INFO="[${GREEN}INFO${RESET}]"
ERROR="[${RED}ERROR${RESET}]"
WARN="[${YELLOW}WARN${RESET}]"
function INFO() {
    echo -e "${INFO} ${1}"
}
function ERROR() {
    echo -e "${ERROR} ${1}"
}
function WARN() {
    echo -e "${WARN} ${1}"
}

# 定义需要拷贝的文件目录,根据项目情况指定,目前无需变动
SERDIR="service"
FONTDIR="dist"
ORIGINAL=${PWD}

# 定义安装重试次数
attempts=0
maxAttempts=3

INFO "======================= 检查环境 ======================="
function CHECK_PACKAGE_MANAGER() {
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

function CHECKMEM() {
INFO "Checking server memory resources. Please wait."

# 获取内存使用率，并保留两位小数
memory_usage=$(free | awk '/^Mem:/ {printf "%.2f", $3/$2 * 100}')

# 将内存使用率转为整数（去掉小数部分）
memory_usage=${memory_usage%.*}

if [[ $memory_usage -gt 70 ]]; then  # 判断是否超过 70%
    read -p "Warning: Memory usage is higher than 70%($memory_usage%). Do you want to continue? (y/n) " continu
    if [ "$continu" == "n" ] || [ "$continu" == "N" ]; then
        exit 1
    fi
else
    INFO "Memory resources are sufficient. Please continue. ($memory_usage%)"
fi

}

function CHECKFIRE() {
INFO "Firewall  detection."
firewall_status=$(systemctl is-active firewalld)
if [[ $firewall_status == 'active' ]]; then
    # If firewall is enabled, disable it
    systemctl stop firewalld
    systemctl disable firewalld
    INFO "Firewall has been disabled."
else
    INFO "Firewall is already disabled."
fi

}

function INSTALL_PACKAGE() {
# 安装软件超时时间,单位秒
TIMEOUT=300
INFO "Installing necessary system components. please wait..."

# 定义要安装的软件包列表
PACKAGES_APT=("lsb-core" "wget" "git" "curl" "lsof")

for package in "${PACKAGES_APT[@]}"; do
    if dpkg -s "$package" &>/dev/null; then
        echo -e "${WARN} 已经安装 $package ..."
    else
        echo -e "${INFO} 正在安装 $package ..."

        # 记录开始时间
        start_time=$(date +%s)

        # 安装软件包并等待完成
        $package_manager -y install "$package" &> /dev/null 2>&1 &
        install_pid=$!

        # 检查安装是否超时
        while [[ $(($(date +%s) - $start_time)) -lt $TIMEOUT ]] && kill -0 $install_pid &>/dev/null; do
            sleep 1
        done

        # 如果安装仍在运行，提示用户
        if kill -0 $install_pid &>/dev/null; then
            ERROR "$package 的安装时间超过 $TIMEOUT 秒。是否继续？ (y/n)"
            read -r continue_install
            if [ "$continue_install" != "y" ]; then
                ERROR "$package 的安装超时。退出脚本。"
                exit 1
            else
                # 直接跳过等待，继续下一个软件包的安装
                continue
            fi
        fi

        # 检查安装结果
        wait $install_pid
        if [ $? -ne 0 ]; then
            ERROR "$package 安装失败。请检查系统安装源，然后再次运行此脚本！请尝试手动执行安装：$package_manager -y install $package"
            exit 1
        fi
    fi
done 
}

function INSTALL_NGINX() {
INFO "=======================安装NGINX======================="
# 检查是否已安装Nginx
if which nginx &>/dev/null; then
  INFO "Nginx is already installed."
else
  INFO "Installing Nginx..."
  while [ $attempts -lt $maxAttempts ]; do
      $package_manager install nginx -y &>/dev/null
      if [ $? -ne 0 ]; then
          ((attempts++))
          WARN "尝试安装Nginx (Attempt: $attempts)"

          if [ $attempts -eq $maxAttempts ]; then
              ERROR "Nginx安装失败，请尝试手动执行安装。"
              echo "命令：$package_manager install nginx -y"
              exit 1
          fi
      else
          INFO "Nginx installed."
          break
      fi
  done
fi

# 检查Nginx是否正在运行
if pgrep "nginx" > /dev/null;then
    INFO "Nginx is already running."
else
    WARN "Nginx is not running. Starting Nginx..."
    systemctl start nginx
    systemctl enable nginx &>/dev/null
    INFO "Nginx started."
fi

}


function NODEJS() {
    INFO "=======================安装NODEJS======================="
    # 检查是否安装了Node.js
    if ! command -v node &> /dev/null; then
        INFO "Node.js is not installed, installation in progress, please wait..."
        
        # 安装前的准备工作，不受系统版本影响
        prepare_for_install() {
            local required_packages=("libstdc++.so.glibc" "glibc")
            for package in "${required_packages[@]}"; do
                if ! command -v "$package" &> /dev/null; then
                    $package_manager -y install "$package" &>/dev/null
                fi
            done
        }
        
        prepare_for_install
        
        install_nodejs() {
            echo -e "${INFO} ${GREEN}Select Node.js version to install:${RESET}"
            echo -e "1. lts.x"
            echo -e "2. 21.x"
            echo -e "3. 20.x"
            echo -e "4. 18.x"
            echo -e "5. 17.x"
            echo -e "6. 16.x"
        echo -e "7. Exit"
        read -e -p "$(echo -e ${INFO} ${GREEN}"Please enter the corresponding number: "${RESET})" selected_version
            case $selected_version in
                1)
                    version_url="https://deb.nodesource.com/setup_lts.x"
                    ;;
                2)
                    version_url="https://deb.nodesource.com/setup_21.x"
                    ;;
                3)
                    version_url="https://deb.nodesource.com/setup_20.x"
                    ;;
                4)
                    version_url="https://deb.nodesource.com/setup_18.x"
                    ;;
                6)
                    version_url="https://deb.nodesource.com/setup_17.x"
                    ;;
                6)
                    version_url="https://deb.nodesource.com/setup_16.x"
                    ;;
                *)
                    echo "Invalid Node.js version selected."
                    exit 1
                    ;;
            esac

        curl -fsSL $version_url | bash -
            if [ $? -ne 0 ]; then
                ERROR "Node.js installation failed!"
                exit 1
            fi
        $package_manager install nodejs -y &>/dev/null
            if [ $? -ne 0 ]; then
                ERROR "Node.js installation failed!"
                exit 2
            fi

            while [ $attempts -lt $maxAttempts ]; do
                $package_manager install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1 --nogpgcheck &>/dev/null
                if [ $? -ne 0 ]; then
                    ((attempts++))
                    WARN "Attempting to install Node.js >>> (Attempt: $attempts)"

                    if [ $attempts -eq $maxAttempts ]; then
                        ERROR "Node.js installation failed. Please try installing manually."
                        echo "Command：$package_manager install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1"
                        exit 1
                    fi
                else
                    INFO "Node.js installation successful."
                    break
                fi
            done
        }

        install_nodejs      
    else
        INFO "Node.js has been installed."
    fi
    
    # 检查是否安装了 pnpm
    if ! command -v pnpm &> /dev/null; then
        INFO "======================= 安装PNPM======================="
        # 安装 pnpm
        while [ $attempts -lt $maxAttempts ]; do           
            npm install -g pnpm &>/dev/null
            if [ $? -ne 0 ]; then
                ((attempts++))
                WARN "Attempting to install pnpm >>> (Attempt: $attempts)"

                if [ $attempts -eq $maxAttempts ]; then
                    ERROR "pnpm installation failed. Please try installing manually."
                    ERROR "Command：npm install -g pnpm"
                    exit 1
                fi
            else
                INFO "pnpm installation successful."
                break
            fi
        done
    else
        INFO "pnpm has been installed." 
    fi

    INFO "安装构建所需的Node.js工具包"
    # 定义最大尝试次数
    maxAttempts=3

    # 定义 npm 软件包数组
    packages=("run-p" "rimraf")

    # 检查 npm 包是否已经安装
    is_package_installed() {
        local package=$1
        npm list -g "$package" >/dev/null2>&1
        return $?
    }


    # 定义安装函数
    install_package() {
        local package=$1
        local attempts=0

        # 检查是否已经安装
        if is_package_installed "$package"; then
            echo -e "${WARN} 已经安装 $package ..."
        else
            echo -e "${INFO} 正在安装 $package ..."
            while [ $attempts -lt $maxAttempts ]; do
                npm install -g "$package" &>/dev/null
                if [ $? -ne 0 ]; then
                    ((attempts++))
                    WARN "Attempting to install $package (Attempt: $attempts)"
                else
                    return 0
                fi

                if [ $attempts -eq $maxAttempts ]; then
                    ERROR "$package installation failed. Please try installing manually."
                    ERROR "Command: npm install -g $package"
                    return 1
                fi
            done
        fi
    }

    # 使用 for 循环来安装数组中的每个包
    for package in "${packages[@]}"; do
        install_package "$package"
    done
}


function MONGO_USER() {
# 检查用户是否要创建 MongoDB 用户
WARN ">>> 提醒：如果之前创建过用户,请勿再次创建同名的用户！<<<"
read -e -p "是否创建 MongoDB 用户？[y/n] " choice
case "$choice" in
  y|Y )
    read -e -p "请输入 MongoDB 账户：" MONGODB_USERNAME
    read -e -p "请输入 MongoDB 密码：" MONGODB_PASSWORD
    mongosh <<EOF >/dev/null 2>&1
    use admin
    db.createUser({
        user: "$MONGODB_USERNAME",
        pwd: "$MONGODB_PASSWORD",
        roles: [ { role: "readWrite", db: "admin" } ]
    })
EOF
    INFO "MongoDB 用户已创建。"
    ;;
  n|N )
    WARN "跳过创建 MongoDB 用户。"
    ;;
  * )
    ERROR "无效的选项，请重新运行脚本。"
    exit 1
    ;;
esac
}

function MONGO() {
INFO "=======================安装Mongo======================="
# 检查当前操作系统类型
if [ "$(uname -s)" != "Linux" ]
then
    ERROR "Error: This script only works on Linux systems."
    exit 1
fi

# 检查当前操作系统版本
if [[ "$(lsb_release -is)" == "Ubuntu" ]]
then
    version=$(cat /etc/os-release | grep VERSION_ID | cut -d '"' -f 2 | cut -d '.' -f 1)
    if [[ "$version" -ge "22" ]]
    then
        # 安装 MongoDB 6.0 on Ubuntu 22.04 or later
	wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add - &> /dev/null
	echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list &> /dev/null
    elif [[ "$version" -ge "20" ]]
    then
        # 安装 MongoDB 5.0 on Ubuntu 20.04 or later
        wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add - &> /dev/null
        echo "deb https://mirrors.tuna.tsinghua.edu.cn/mongodb/apt/ubuntu focal/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb.list &> /dev/null
    elif [[ "$version" -ge "18" ]]
    then
        # 安装 MongoDB 5.0 on Ubuntu 18.04 or later
        wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add - &> /dev/null
        echo "deb https://mirrors.tuna.tsinghua.edu.cn/mongodb/apt/ubuntu bionic/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb.list &> /dev/null
    else
        echo "Error: Unsupported Ubuntu version."
        exit 1
    fi
elif [[ "$(lsb_release -is)" == "Debian" ]]
then
    version=$(cat /etc/os-release | grep VERSION_ID | cut -d '"' -f 2 | cut -d '.' -f 1)
    if [[ "$version" -ge "11" ]]
    then
        # 安装 MongoDB 5.0 on Debian 11 or later
        wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add - &> /dev/null
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/debian bullseye/mongodb-org/5.0 main" | sudo tee /etc/apt/sources.list.d/mongodb.list &> /dev/null
    elif [[ "$version" -ge "10" ]]
    then
        # 安装 MongoDB 5.0 on Debian 10 or later
        wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add - &> /dev/null
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main" | sudo tee /etc/apt/sources.list.d/mongodb.list &> /dev/null
    else
        ERROR "Error: Unsupported Debian version."
        exit 1
    fi
else
    ERROR "Error: Unsupported operating system."
    exit 1
fi
# 更新软件包列表并安装 MongoDB
$package_manager update &> /dev/null
while [[ $attempts -lt $maxAttempts ]]; do
    $package_manager install -y mongodb-org &> /dev/null
    if [ $? -ne 0 ]; then
        ((attempts++))
        WARN "尝试安装mongodb (Attempt: $attempts)"

        if [[ $attempts -eq $maxAttempts ]]; then
            ERROR "mongodb安装失败，请尝试手动执行安装。"
            echo "命令：$package_manager install -y mongodb-org"
            exit 1
        fi
    else
        INFO "MongoDB installed."
        break
    fi
done

# 启动 MongoDB 服务并设置开机自启
if systemctl is-active mongod >/dev/null 2>&1; then
    INFO "MongoDB 已启动"
    MONGO_USER
else
    systemctl daemon-reexec &>/dev/null
    systemctl enable --now mongod &>/dev/null
    if systemctl is-active mongod >/dev/null 2>&1; then
        INFO "MongoDB 启动成功"
        MONGO_USER
    else
        ERROR "MongoDB 启动失败"
        exit 1
    fi
fi

}

function GITCLONE() {
    INFO "======================= 开始安装 ======================="
    rm -rf chatgpt-web* &>/dev/null
    CGPTWEB="https://github.com/Chanzhaoyu/chatgpt-web"
    KGPTWEB="https://github.com/Kerwin1202/chatgpt-web"
    ZGPTWEB="https://github.com/zhujunsan/chatgpt-web"
    BGPTWEB="https://github.com/BobDu/chatgpt-web-fork"

    INFO "请选择要克隆的仓库："
    echo "-------------------------------------------------"
    echo "1. Chanzhaoyu/chatgpt-web [用户管理--No]"
    echo "2. Kerwin1202/chatgpt-web [用户管理-Yes]"
    echo "3. zhujunsan/chatgpt-web  [用户管理-Yes]"
    echo "4. BobDu/chatgpt-web-fork [用户管理-Yes]"
    echo "-------------------------------------------------"

    for i in {1..5}; do
        read -e -n1 inputgpt
        case $inputgpt in
            1) repository=$CGPTWEB; CHATDIR=chatgpt-web; break;;
            2) repository=$KGPTWEB; CHATDIR=chatgpt-web; break;;
            3) repository=$ZGPTWEB; CHATDIR=chatgpt-web; break;;
            4) repository=$BGPTWEB; CHATDIR=chatgpt-web-fork; break;;
            *) ERROR "Invalid option, please retry.";;
        esac

        if [ $i -eq 4 ]; then
            ERROR "Option input error 3 times, exiting the script."
            exit 1
        fi
    done

    attempts=0
    while true; do
        INFO "请选择克隆的项目分支："
        echo "-------------------------------------------------"
        echo "1. 默认分支"
        echo "2. 自选分支"
        echo "-------------------------------------------------"

        read -e -n1 input
        case $input in
            1)
                #if git clone https://mirror.ghproxy.com/$repository; then
		if git clone $repository; then
                    break
                else
                    ((attempts++))
                    ERROR "Git clone failed, please retry. (Attempt: $attempts)"
                    if [ $attempts -ge 3 ]; then
                        ERROR "Exceeded maximum attempts. Exiting script."
                        exit 1
                    fi
                fi
                ;;
            2)
                INFO "请输入要克隆的分支名称："
                echo "-------------------------------------------------"
                read -e branch
                echo "-------------------------------------------------"
                if [ -z "$branch" ]; then
                    ERROR "分支名称不能为空，请重新输入。"
                    continue
                fi

                while true; do
                    if git clone -b $branch $repository; then
                        break
                    else
                        ((attempts++))
                        ERROR "Git clone failed, please retry. (Attempt: $attempts)"
                        if [ $attempts -ge 3 ]; then
                            ERROR "Exceeded maximum attempts. Exiting script."
                            exit 2
                        fi
                    fi
                done
                break
                ;;
            *)
                ERROR "Invalid option, please retry."
                input=
                continue
                ;;
        esac
    done
    
}

function WEBINFO() {
INFO "构建之前请先指定Nginx根路径!"

# 交互输入Nginx根目录(提前进行创建好)
if [ -f .input ]; then
  last_input=$(cat .input)
  read -e -p "WEB存储绝对路径[上次记录：${last_input} 回车用上次记录]：" WEBDIR
  if [ -z "${WEBDIR}" ];then
      WEBDIR="$last_input"
      INFO "ChatGPT-WEB存储路径：${WEBDIR}"
  else
      INFO "ChatGPT-WEB存储路径：${WEBDIR}"
  fi
else
  read -e -p "WEB存储绝对路径(回车默认Nginx路径)：" WEBDIR
  if [ -z "${WEBDIR}" ];then
      WEBDIR="/usr/share/nginx/html"
      INFO "ChatGPT-WEB存储路径：${WEBDIR}"
  else
      INFO "ChatGPT-WEB存储路径：${WEBDIR}"
  fi
fi
echo "${WEBDIR}" > .input
}

function USERINFO() {
if [ -f .userinfo ]; then
  user_input=$(cat .userinfo)
  read -e -p "修改用户默认名称/描述/头像信息,请用空格分隔[上次记录：${user_input} 回车用上次记录]：" USERINFO
  if [ -z "${USERINFO}" ];then
      USERINFO="$user_input"
      USER=$(echo "${USERINFO}" | cut -d' ' -f1)
      INFO=$(echo "${USERINFO}" | cut -d' ' -f2)
      AVATAR=$(echo "${USERINFO}" | cut -d' ' -f3)
      INFO "当前用户默认名称为：${USER}"
      INFO "当前描述信息默认为：${INFO}"
      # 修改个人信息
      sed -i "s/ChenZhaoYu/${USER}/g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      sed -i "s/Star on <a href=\"https:\/\/github.com\/Chanzhaoyu\/chatgpt-bot\" class=\"text-blue-500\" target=\"_blank\" >GitHub<\/a>/${INFO}/g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      sed -i "s#https://raw.githubusercontent.com/Chanzhaoyu/chatgpt-web/main/src/assets/avatar.jpg#${AVATAR}#g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      # 删除配置里面的GitHub相关信息内容(可选，建议保留，尊重项目作者成果)
      #sed -i '/<div class="p-2 space-y-2 rounded-md bg-neutral-100 dark:bg-neutral-700">/,/<\/div>/d' ${ORIGINAL}/${CHATDIR}/src/components/common/Setting/About.vue
  else
      USER=$(echo "${USERINFO}" | cut -d' ' -f1)
      INFO=$(echo "${USERINFO}" | cut -d' ' -f2)
      AVATAR=$(echo "${USERINFO}" | cut -d' ' -f3)
      INFO "当前用户默认名称为：${USER}"
      INFO "当前描述信息默认为：${INFO}"
      # 修改个人信息
      sed -i "s/ChenZhaoYu/${USER}/g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      sed -i "s/Star on <a href=\"https:\/\/github.com\/Chanzhaoyu\/chatgpt-bot\" class=\"text-blue-500\" target=\"_blank\" >GitHub<\/a>/${INFO}/g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      sed -i "s#https://raw.githubusercontent.com/Chanzhaoyu/chatgpt-web/main/src/assets/avatar.jpg#${AVATAR}#g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      # 删除配置里面的GitHub相关信息内容(可选，建议保留，尊重项目作者成果)
      #sed -i '/<div class="p-2 space-y-2 rounded-md bg-neutral-100 dark:bg-neutral-700">/,/<\/div>/d' ${ORIGINAL}/${CHATDIR}/src/components/common/Setting/About.vue
   fi
else
   read -e -p "修改用户默认名称/描述/头像信息,请用空格分隔[回车保持默认不做修改]：" USERINFO
   if [ -z "${USERINFO}" ];then
      INFO "没有输入,保持默认"
   else
      USER=$(echo "${USERINFO}" | cut -d' ' -f1)
      INFO=$(echo "${USERINFO}" | cut -d' ' -f2)
      AVATAR=$(echo "${USERINFO}" | cut -d' ' -f3)
      INFO "当前用户默认名称为：${USER}"
      INFO "当前描述信息默认为：${INFO}"
      # 修改个人信息
      sed -i "s/ChenZhaoYu/${USER}/g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      sed -i "s/Star on <a href=\"https:\/\/github.com\/Chanzhaoyu\/chatgpt-bot\" class=\"text-blue-500\" target=\"_blank\" >GitHub<\/a>/${INFO}/g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      sed -i "s#https://raw.githubusercontent.com/Chanzhaoyu/chatgpt-web/main/src/assets/avatar.jpg#${AVATAR}#g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      # 删除配置里面的GitHub相关信息内容(可选，建议保留，尊重项目作者成果)
      #sed -i '/<div class="p-2 space-y-2 rounded-md bg-neutral-100 dark:bg-neutral-700">/,/<\/div>/d' ${ORIGINAL}/${CHATDIR}/src/components/common/Setting/About.vue
   fi
fi
[ -n "${USERINFO}" ] && echo "${USERINFO}" > .userinfo
}


function WEBTITLE() {
INFO "构建之前请先命名你的网站标题!"

# 交互输入Nginx根目录(提前进行创建好)
if [ -f .webtitle ]; then
  last_input=$(cat .webtitle)
  read -e -p "网站标题[上次记录：${last_input} 回车用上次记录]：" TITLE
  if [ -z "${TITLE}" ];then
      TITLE="$last_input"
      INFO "网站标题命名为：${TITLE}"
      sed -i "s/\${SITE_TITLE}/${TITLE}/g" ${ORIGINAL}/${CHATDIR}/index.html
  else
      INFO "网站标题命名为：${TITLE}"
      sed -i "s/\${SITE_TITLE}/${TITLE}/g" ${ORIGINAL}/${CHATDIR}/index.html
  fi
else
  read -e -p "网站标题(回车默认标题)：" TITLE
  if [ -z "${TITLE}" ];then
      TITLE="ChatGPT WEB"
      INFO "网站标题命名为：${TITLE}"
      sed -i "s/\${SITE_TITLE}/${TITLE}/g" ${ORIGINAL}/${CHATDIR}/index.html
  else
      INFO "网站标题命名为：${TITLE}"
      sed -i "s/\${SITE_TITLE}/${TITLE}/g" ${ORIGINAL}/${CHATDIR}/index.html
  fi
fi
echo "${TITLE}" > .webtitle
}


function BUILDWEB() {
INFO "《前端构建中,请稍等...执行过程中请勿进行操作》"
# 安装依赖
pnpm bootstrap 2>&1 >/dev/null | grep -E "error|fail|warning"
# 打包
pnpm build | grep -E "ERROR|ELIFECYCLE|WARN|*built in*"
}

function BUILDSEV() {
INFO "《后端构建中,请稍等...执行过程中请勿进行操作》"
# 安装依赖
pnpm install 2>&1 >/dev/null | grep -E "error|fail|warning"
# 打包
pnpm build | grep -E "ERROR|ELIFECYCLE|WARN|*Build success*"
}


function BUILD() {
INFO "开始进行构建.构建快慢取决于你的环境"

# 拷贝.env配置替换
# 拷贝.env配置替换
if [ ! -f "${ORIGINAL}/env.example" ]; then
    ERROR "File 'env.example' not found. Please make sure it exists."
    exit 1
fi
INFO "======================= 构建前端 ======================="
# 前端
cd ${ORIGINAL}/${CHATDIR} && BUILDWEB
directory="${ORIGINAL}/${CHATDIR}/${FONTDIR}"
if [ ! -d "$directory" ]; then
    ERROR "Frontend build failed..."
    exit 1
fi
INFO
INFO "======================= 构建后端 ======================="
# 后端
cd ${SERDIR} && BUILDSEV
}


# 拷贝构建成品到Nginx网站根目录
function NGINX() {
# 拷贝后端并启动
INFO "======================= 开始部署 ======================="
\cp -fr ${ORIGINAL}/${CHATDIR}/${SERDIR} ${WEBDIR}
# 检测返回值
if [ $? -eq 0 ]; then
    # 如果指令执行成功，则继续运行下面的操作
    INFO "Service Copy Success"
else
    # 如果指令执行不成功，则输出错误日志，并退出脚本
    ERROR "Copy Error"
    exit 1
fi
# 检查名为 node后端 的进程是否正在运行
pid=$(lsof -t -i:3002)
if [ -z "$pid" ]; then
    INFO "后端程序未运行,启动中..."
else
    INFO "后端程序正在运行,现在停止程序并更新..."
    kill -9 $pid
fi
\cp -fr ${ORIGINAL}/${CHATDIR}/${FONTDIR}/* ${WEBDIR}
# 检测返回值
if [ $? -eq 0 ]; then
    # 如果指令执行成功，则继续运行下面的操作
    INFO "WEB Copy Success"
else
    # 如果指令执行不成功，则输出错误日志，并退出脚本
    ERROR "Copy Error"
    exit 2
fi
# 添加开机自启
cat > /etc/systemd/system/chatgpt-web.service <<EOF
[Unit]
Description=ChatGPT Web Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${WEBDIR}/${SERDIR}
ExecStart=$(which pnpm) run start
Restart=always
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
TimeoutStopSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl restart chatgpt-web
systemctl enable chatgpt-web &>/dev/null

sleep 10
if pgrep -x "node" > /dev/null
then
    # 检测端口是否正在监听
    if ss -tuln | grep ":3002" > /dev/null
    then
        INFO "chatgpt-web后端服务已成功启动"
    else
        ERROR "ChatGPT-WEB 后端服务端口 3002 未在监听"
        ERROR "-----------ChatGPT-WEB 后端服务启动失败，请查看错误日志 ↓↓↓-----------"
          journalctl -u chatgpt-web --no-pager
        ERROR "-----------ChatGPT-WEB 后端服务启动失败，请查看错误日志 ↑↑↑-----------"
        exit 3
    fi
else
    ERROR "ChatGPT-WEB 后端服务进程未找到"
    ERROR "-----------ChatGPT-WEB 后端服务启动失败，请查看错误日志 ↓↓↓-----------"
      journalctl -u chatgpt-web --no-pager
    ERROR "-----------ChatGPT-WEB 后端服务启动失败，请查看错误日志 ↑↑↑-----------"
    echo
    exit 4
fi


# 拷贝前端刷新Nginx服务
if ! nginx -t ; then
    ERROR "ChatGPT-WEB Nginx 配置文件存在错误，请检查配置"
    exit 5
else
    nginx -s reload
fi
}

function WEBURL(){
# 获取公网IP
PUBLIC_IP=$(curl -s https://ifconfig.me)

# 获取所有网络接口的IP地址
ALL_IPS=$(hostname -I)

# 排除不需要的地址（127.0.0.1和docker0）
INTERNAL_IP=$(echo "$ALL_IPS" | awk '$1!="127.0.0.1" && $1!="::1" && $1!="docker0" {print $1}')

INFO "请用浏览器访问面板: "
INFO "公网访问地址: http://$PUBLIC_IP"
INFO "内网访问地址: http://$INTERNAL_IP"
INFO
INFO "作者博客: https://dqzboy.com"
INFO "技术交流: https://t.me/dqzboyblog"
INFO "代码仓库: https://github.com/dqzboy/chatgpt-web"
INFO  
INFO "如果使用的是云服务器，请至安全组开放 80 端口"
INFO "公网访问地址: http://$PUBLIC_IP"
INFO "内网访问地址: http://$INTERNAL_IP"
INFO
}

# 删除源码包文件
function DELSOURCE() {
  rm -rf ${ORIGINAL}/${CHATDIR}
  INFO
  INFO "=================感谢您的耐心等待，安装已经完成=================="
  INFO
    WEBURL
  INFO "================================================================"
}

# 添加Nginx后端代理配置
function NGINX_CONF() {
read -e -p "是否修改Nginx配置[y/n](通过本脚本部署的Nginx可选择 y)：" NGCONF
if [ "$NGCONF" = "y" ]; then
   INFO "You chose yes."
   INFO "config：/etc/nginx/nginx.conf"
cat > /etc/nginx/nginx.conf <<\EOF
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 768;
    # multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;

    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80;
        server_name  localhost;

        #access_log  /var/log/nginx/host.access.log  main;

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
}
EOF
elif [ "$NGCONF" = "n" ]; then
   WARN "You chose no."
else
   ERROR "Invalid parameter. Please enter 'y' or 'n'."
   exit 1
fi
}

function REPO() {
# 判断 repository 的值
if [ $repository == $CGPTWEB ]; then
    WEBINFO
    USERINFO
elif [ $repository == $KGPTWEB ]; then
    MONGO
    WEBINFO
    #WEBTITLE
elif [ $repository == $ZGPTWEB ]; then
    MONGO
    WEBINFO
    WEBTITLE
elif [ $repository == $BGPTWEB ]; then
    MONGO
    WEBINFO
    #WEBTITLE
fi
}

function main() {
    CHECK_PACKAGE_MANAGER
    CHECKMEM
    CHECKFIRE
    
    while true; do
        read -e -p "$(echo -e ${INFO} ${GREEN}"是否执行软件包安装? [y/n]: "${RESET})" choice_package
        case "$choice_package" in
            y|Y )
                INSTALL_PACKAGE
                break;;
            n|N )
                WARN "跳过软件包安装步骤。"
                break;;
            * )
                INFO "请输入 'y' 表示是，或者 'n' 表示否。";;
        esac
    done

    GITCLONE
    INSTALL_NGINX
    NODEJS
    REPO
    BUILD
    NGINX_CONF
    NGINX
    DELSOURCE
}
main
