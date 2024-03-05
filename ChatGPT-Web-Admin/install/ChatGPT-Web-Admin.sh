#!/usr/bin/env bash
#===============================================================================
#
#          FILE: ChatGPT-Web-Admin.sh
# 
#         USAGE: ./ChatGPT-Web-Admin.sh
#
#   DESCRIPTION: chatGPT-WEB项目一键构建、部署脚本
# 
#  ORGANIZATION: DingQz dqzboy.com 浅时光博客
#===============================================================================

SETCOLOR_SKYBLUE="echo -en \\E[1;36m"
SETCOLOR_SUCCESS="echo -en \\E[0;32m"
SETCOLOR_NORMAL="echo  -en \\E[0;39m"
SETCOLOR_RED="echo  -en \\E[0;31m"
SETCOLOR_YELLOW="echo -en \\E[1;33m"

# 定义需要拷贝的文件目录,根据项目情况指定,目前无需变动
SERDIR="service"
FONTDIR="dist"
ORIGINAL=${PWD}

# 定义安装重试次数
attempts=0
maxAttempts=3

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
echo
echo -e "\033[32m机场推荐\033[0m(\033[34m按量不限时，解锁ChatGPT\033[0m)：\033[34;4mhttps://mojie.mx/#/register?code=CG6h8Irm\033[0m"
echo
echo "----------------------------------------------------------------------------------------------------------"

SUCCESS() {
  ${SETCOLOR_SUCCESS} && echo "------------------------------------< $1 >-------------------------------------"  && ${SETCOLOR_NORMAL}
}

SUCCESS1() {
  ${SETCOLOR_SUCCESS} && echo "$1"  && ${SETCOLOR_NORMAL}
}

ERROR() {
  ${SETCOLOR_RED} && echo "$1"  && ${SETCOLOR_NORMAL}
}

INFO() {
  ${SETCOLOR_SKYBLUE} && echo "$1"  && ${SETCOLOR_NORMAL}
}

WARN() {
  ${SETCOLOR_YELLOW} && echo "$1"  && ${SETCOLOR_NORMAL}
}

function CHECK_PACKAGE_MANAGER() {
    if command -v dnf &> /dev/null; then
        package_manager="dnf"
    elif command -v yum &> /dev/null; then
        package_manager="yum"
    else
        ERROR "Unsupported package manager."
        exit 1
    fi
}

function CHECK_PKG_MANAGER() {
    if command -v rpm &> /dev/null; then
        pkg_manager="rpm"
    else
        ERROR "Unable to determine the package management system."
        exit 1
    fi
}

# 进度条
function Progress() {
spin='-\|/'
count=0
endtime=$((SECONDS+3))

while [ $SECONDS -lt $endtime ];
do
    spin_index=$(($count % 4))
    printf "\r[%c] " "${spin:$spin_index:1}"
    sleep 0.1
    count=$((count + 1))
done
}

DONE () {
Progress && SUCCESS1 ">>>>> Done"
echo
}

# OS version
OSVER=$(cat /etc/os-release | grep -o '[0-9]' | head -n 1)

function CHECKMEM() {
INFO "Checking server memory resources. please wait..."

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
    SUCCESS1 "Memory resources are sufficient. Please continue.($memory_usage%)"
fi
DONE
}

function CHECKFIRE() {
SUCCESS "Firewall && SELinux detection."
firewall_status=$(systemctl is-active firewalld)
if [[ $firewall_status == 'active' ]]; then
    systemctl stop firewalld
    systemctl disable firewalld
    INFO "Firewall has been disabled."
else
    INFO "Firewall is already disabled."
fi

if sestatus | grep "SELinux status" | grep -q "enabled"; then
    WARN "SELinux is enabled. Disabling SELinux..."
    setenforce 0
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    INFO "SELinux is already disabled."
else
    INFO "SELinux is already disabled."
fi
DONE
}

function INSTALL_PACKAGE() {
TIMEOUT=300
SUCCESS "Install necessary system components."
INFO "Installing necessary system components. please wait..."

# 定义要安装的软件包列表
PACKAGES_YUM=("epel-release" "wget" "git" "lsof" "openssl-devel" "zlib-devel" "gd-devel" "pcre-devel" "pcre2")

for package in "${PACKAGES_YUM[@]}"; do
    if $pkg_manager -q "$package" &>/dev/null; then
        echo "已经安装 $package ..."
    else
        echo "正在安装 $package ..."

        # 记录开始时间
        start_time=$(date +%s)

        # 安装软件包并等待完成
        $package_manager -y install "$package" --skip-broken > /dev/null 2>&1 &
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

SUCCESS1 "System components installation completed."
DONE
}

function INSTALL_NGINX() {
    SUCCESS "Nginx detection and installation."

    # 检查是否已安装Nginx
    if which nginx &>/dev/null; then
        SUCCESS1 "Nginx is already installed."
    else
        INFO "Installing Nginx program, please wait..."
        NGINX="nginx-1.24.0-1.el${OSVER}.ngx.x86_64.rpm"

        # 下载并安装RPM包
        rm -f ${NGINX}
        wget http://nginx.org/packages/centos/${OSVER}/x86_64/RPMS/${NGINX} &>/dev/null
        while [ $attempts -lt $maxAttempts ]; do
            $package_manager -y install ${NGINX} &>/dev/null

            if [ $? -ne 0 ]; then
                ((attempts++))
                WARN "Attempting to install Nginx >>> (Attempt: $attempts)"

                if [ $attempts -eq $maxAttempts ]; then
                    ERROR "Nginx installation failed. Please try installing manually."
                    rm -f ${NGINX}
                    echo "Command：wget http://nginx.org/packages/centos/${OSVER}/x86_64/RPMS/${NGINX} && $package_manager -y install ${NGINX}"
                    exit 1
                fi
            else
                INFO "Nginx installed."
                rm -f ${NGINX}
                break
            fi
        done
    fi

    # 定义一个函数来启动 Nginx
    start_nginx() {
        systemctl enable nginx &>/dev/null
        systemctl restart nginx
    }

    # 检查 Nginx 是否正在运行
    if pgrep "nginx" > /dev/null; then
        SUCCESS1 "Nginx is already running."
    else
        WARN "Nginx is not running. Attempting to start Nginx..."
        start_attempts=3

        # 最多尝试启动 3 次
        for ((i=1; i<=$start_attempts; i++)); do
            start_nginx
            if pgrep "nginx" > /dev/null; then
                SUCCESS1 "Nginx has been successfully started."
                break
            else
                if [ $i -eq $start_attempts ]; then
                    ERROR "Nginx couldn't start after $start_attempts attempts. Please check the configuration."
                    exit 1
                else
                    WARN "Failed to start Nginx for the $i time. Retrying..."
                fi
            fi
        done
    fi

    DONE
}

function NODEJS() {
    SUCCESS "Node.js detection and installation."
    
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
        
        # 使用不同的包管理工具安装Node.js
        install_nodejs() {
	    echo "--------------------------------------------------------"
            echo -e "${GREEN}Select Node.js version to install:${RESET}"
            echo -e "1. lts.x"
            echo -e "2. 21.x"
            echo -e "3. 20.x"
            echo -e "4. 18.x"
            echo -e "5. 17.x"
            echo -e "6. 16.x"
	    echo -e "7. Exit"
	    read -e -p "$(echo -e ${GREEN}"Please enter the corresponding number: "${RESET})" selected_version
            case $selected_version in
                1)
                    version_url="https://rpm.nodesource.com/setup_lts.x"
                    ;;
                2)
                    version_url="https://rpm.nodesource.com/setup_21.x"
                    ;;
                3)
                    version_url="https://rpm.nodesource.com/setup_20.x"
                    ;;
                4)
                    version_url="https://rpm.nodesource.com/setup_18.x"
                    ;;
                6)
                    version_url="https://rpm.nodesource.com/setup_17.x"
                    ;;
                6)
                    version_url="https://rpm.nodesource.com/setup_16.x"
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
                    SUCCESS1 "Node.js installation successful."
                    break
                fi
            done
        }

        install_nodejs      
    else
        SUCCESS1 "Node.js has been installed."
    fi
    
    # 检查是否安装了 pnpm
    if ! command -v pnpm &> /dev/null; then
        INFO "pnpm is not installed, installation in progress, please wait..."
        
        # 安装 pnpm
        while [ $attempts -lt $maxAttempts ]; do
            npm install -g pnpm &>/dev/null
            if [ $? -ne 0 ]; then
                ((attempts++))
                WARN "Attempting to install pnpm >>> (Attempt: $attempts)"

                if [ $attempts -eq $maxAttempts ]; then
                    ERROR "pnpm installation failed. Please try installing manually."
                    echo "Command：npm install -g pnpm"
                    exit 1
                fi
            else
                SUCCESS1 "pnpm installation successful."
                break
            fi
        done
    else
        SUCCESS1 "pnpm has been installed." 
    fi
    
    DONE
}


function MONGO_USER() {
# 检查用户是否要创建 MongoDB 用户
WARN ">>> 提醒：如果之前创建过用户,请勿再次创建同名的用户！<<<"
read -e -p "是否创建 MongoDB 用户？[y/n] " choice
case "$choice" in
  y|Y )
    read -e -p "请输入 MongoDB 用户名：" MONGODB_USERNAME
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
    SUCCESS "Check MongoDB and install it."

    # 检查 MongoDB 仓库配置文件是否存在
    if [ ! -f /etc/yum.repos.d/mongodb-org-6.0.repo ]; then
        cat > /etc/yum.repos.d/mongodb-org-6.0.repo <<EOF
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/${OSVER}/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF
    fi

    # 安装 MongoDB
    install_mongodb() {
        INFO "Installing MongoDB program, please wait..."
        $package_manager install -y mongodb-org &>/dev/null
        if [ $? -ne 0 ]; then
            ERROR "MongoDB installation failed. Please try installing manually."
            echo "Command: $package_manager install -y mongodb-org"
            exit 1
        else
            SUCCESS1 "MongoDB installation successful."
        fi
    }

    # 检查 MongoDB 是否已经安装
    if ! command -v mongod &> /dev/null; then
        install_mongodb
    fi

    # 定义一个函数来尝试启动 MongoDB
    start_mongodb() {
        systemctl daemon-reexec &>/dev/null
        systemctl enable --now mongod &>/dev/null
    }

    # 检查 MongoDB 是否正在运行
    if systemctl is-active mongod >/dev/null 2>&1; then
        SUCCESS1 "MongoDB is already running."
        MONGO_USER
    else
        WARN "MongoDB is not running. Attempting to start MongoDB..."
        start_attempts=3

        # 最多尝试启动 3 次
        for ((i=1; i<=$start_attempts; i++)); do
            start_mongodb
            if systemctl is-active mongod >/dev/null 2>&1; then
                SUCCESS1 "MongoDB has been successfully started."
                MONGO_USER
                break
            else
                if [ $i -eq $start_attempts ]; then
                    ERROR "MongoDB couldn't start after $start_attempts attempts. Please check the logs."
                    exit 1
                else
                    WARN "Failed to start MongoDB for the $i time. Retrying..."
                fi
            fi
        done
    fi

    DONE
}

function GITCLONE() {
    SUCCESS "ChatGPT Web Project cloning."
    rm -rf chatgpt-web* &>/dev/null
    CGPTWEB="https://github.com/Chanzhaoyu/chatgpt-web"
    KGPTWEB="https://github.com/Kerwin1202/chatgpt-web"
    ZGPTWEB="https://github.com/zhujunsan/chatgpt-web"
    BGPTWEB="https://github.com/BobDu/chatgpt-web-fork"

    ${SETCOLOR_RED} && echo "请选择要克隆的仓库：" && ${SETCOLOR_NORMAL}
    echo "-------------------------------------------------"
    echo "1. Chanzhaoyu/chatgpt-web [用户管理-No]"
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
        echo 
        ${SETCOLOR_RED} && echo "请选择克隆的项目分支：" && ${SETCOLOR_NORMAL}
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
                ${SETCOLOR_RED} && echo "请输入要克隆的分支名称：" && ${SETCOLOR_NORMAL}
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
    DONE
}

function WEBINFO() {
SUCCESS "构建之前请先指定Nginx根路径!"

# 交互输入Nginx根目录(提前进行创建好)
if [ -f .input ]; then
  last_input=$(cat .input)
  read -e -p "WEB存储绝对路径[上次记录：${last_input} 回车用上次记录]：" WEBDIR
  if [ -z "${WEBDIR}" ];then
      WEBDIR="$last_input"
      ${SETCOLOR_SKYBLUE} && echo "chatGPT-WEB存储路径：${WEBDIR}" && ${SETCOLOR_NORMAL}
  else
      ${SETCOLOR_SUCCESS} && echo "chatGPT-WEB存储路径：${WEBDIR}" && ${SETCOLOR_NORMAL}
  fi
else
  read -e -p "WEB存储绝对路径(回车默认Nginx路径)：" WEBDIR
  if [ -z "${WEBDIR}" ];then
      WEBDIR="/usr/share/nginx/html"
      ${SETCOLOR_SKYBLUE} && echo "chatGPT-WEB存储路径：${WEBDIR}" && ${SETCOLOR_NORMAL}
  else
      ${SETCOLOR_SUCCESS} && echo "chatGPT-WEB存储路径：${WEBDIR}" && ${SETCOLOR_NORMAL}
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
      ${SETCOLOR_SUCCESS} && echo "当前用户默认名称为：${USER}" && ${SETCOLOR_NORMAL}
      ${SETCOLOR_SUCCESS} && echo "当前描述信息默认为：${INFO}" && ${SETCOLOR_NORMAL}
      # 修改个人信息
      sed -i "s/ChenZhaoYu/${USER}/g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      sed -i "s/Star on <a href=\"https:\/\/github.com\/Chanzhaoyu\/chatgpt-bot\" class=\"text-blue-500\" target=\"_blank\" >GitHub<\/a>/${INFO}/g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      sed -i "s#https://raw.githubusercontent.com/Chanzhaoyu/chatgpt-web/main/src/assets/avatar.jpg#${AVATAR}#g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      # 删除配置里面的GitHub相关信息内容
      sed -i '/<div class="p-2 space-y-2 rounded-md bg-neutral-100 dark:bg-neutral-700">/,/<\/div>/d' ${ORIGINAL}/${CHATDIR}/src/components/common/Setting/About.vue
  else
      USER=$(echo "${USERINFO}" | cut -d' ' -f1)
      INFO=$(echo "${USERINFO}" | cut -d' ' -f2)
      AVATAR=$(echo "${USERINFO}" | cut -d' ' -f3)
      ${SETCOLOR_SUCCESS} && echo "当前用户默认名称为：${USER}" && ${SETCOLOR_NORMAL}
      ${SETCOLOR_SUCCESS} && echo "当前描述信息默认为：${INFO}" && ${SETCOLOR_NORMAL}
      # 修改个人信息
      sed -i "s/ChenZhaoYu/${USER}/g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      sed -i "s/Star on <a href=\"https:\/\/github.com\/Chanzhaoyu\/chatgpt-bot\" class=\"text-blue-500\" target=\"_blank\" >GitHub<\/a>/${INFO}/g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      sed -i "s#https://raw.githubusercontent.com/Chanzhaoyu/chatgpt-web/main/src/assets/avatar.jpg#${AVATAR}#g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      # 删除配置里面的GitHub相关信息内容
      sed -i '/<div class="p-2 space-y-2 rounded-md bg-neutral-100 dark:bg-neutral-700">/,/<\/div>/d' ${ORIGINAL}/${CHATDIR}/src/components/common/Setting/About.vue
   fi
else
   read -e -p "修改用户默认名称/描述/头像信息,请用空格分隔[回车保持默认不做修改]：" USERINFO
   if [ -z "${USERINFO}" ];then
      ${SETCOLOR_SKYBLUE} && echo "没有输入,保持默认" && ${SETCOLOR_NORMAL}
   else
      USER=$(echo "${USERINFO}" | cut -d' ' -f1)
      INFO=$(echo "${USERINFO}" | cut -d' ' -f2)
      AVATAR=$(echo "${USERINFO}" | cut -d' ' -f3)
      ${SETCOLOR_SUCCESS} && echo "当前用户默认名称为：${USER}" && ${SETCOLOR_NORMAL}
      ${SETCOLOR_SUCCESS} && echo "当前描述信息默认为：${INFO}" && ${SETCOLOR_NORMAL}
      # 修改个人信息
      sed -i "s/ChenZhaoYu/${USER}/g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      sed -i "s/Star on <a href=\"https:\/\/github.com\/Chanzhaoyu\/chatgpt-bot\" class=\"text-blue-500\" target=\"_blank\" >GitHub<\/a>/${INFO}/g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      sed -i "s#https://raw.githubusercontent.com/Chanzhaoyu/chatgpt-web/main/src/assets/avatar.jpg#${AVATAR}#g" ${ORIGINAL}/${CHATDIR}/src/store/modules/user/helper.ts
      # 删除配置里面的GitHub相关信息内容
      sed -i '/<div class="p-2 space-y-2 rounded-md bg-neutral-100 dark:bg-neutral-700">/,/<\/div>/d' ${ORIGINAL}/${CHATDIR}/src/components/common/Setting/About.vue
   fi
fi
[ -n "${USERINFO}" ] && echo "${USERINFO}" > .userinfo
}


function WEBTITLE() {
SUCCESS "构建之前请先命名你的网站标题!"

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
INFO "《前端构建中，请稍等...在构建执行过程中请勿进行任何操作。》"
# 安装依赖
pnpm bootstrap 2>&1 >/dev/null | grep -E "ERROR|FAIL|WARN"
# 打包
pnpm build | grep -E "ERROR|ELIFECYCLE|WARN|*built in*"
}

function BUILDSEV() {
INFO "《后端构建中，请稍等...在构建执行过程中请勿进行任何操作。》"
# 安装依赖
pnpm install 2>&1 >/dev/null | grep -E "ERROR|FAIL|WARN"
# 打包
pnpm build | grep -E "ERROR|ELIFECYCLE|WARN|*Build success*"
}


function BUILD() {
SUCCESS "开始进行构建.构建快慢取决于你的环境"

# 拷贝.env配置替换
if [ ! -f "${ORIGINAL}/env.example" ]; then
    ERROR "File 'env.example' not found. Please make sure it exists."
    exit 1
fi
cp "${ORIGINAL}/env.example" "${ORIGINAL}/${CHATDIR}/${SERDIR}/.env"

echo
${SETCOLOR_SUCCESS} && echo "-----------------------------------<前端构建>-----------------------------------" && ${SETCOLOR_NORMAL}
# 前端
cd ${ORIGINAL}/${CHATDIR} && BUILDWEB
directory="${ORIGINAL}/${CHATDIR}/${FONTDIR}"
if [ ! -d "$directory" ]; then
    ERROR "Frontend build failed..."
    exit 1
fi
${SETCOLOR_SUCCESS} && echo "-------------------------------------< END >-------------------------------------" && ${SETCOLOR_NORMAL}
echo
echo
${SETCOLOR_SUCCESS} && echo "------------------------------------<后端构建>-----------------------------------" && ${SETCOLOR_NORMAL}
# 后端
cd ${SERDIR} && BUILDSEV
${SETCOLOR_SUCCESS} && echo "-------------------------------------< END >-------------------------------------" && ${SETCOLOR_NORMAL}
}


# 拷贝构建成品到Nginx网站根目录
function NGINX() {
# 拷贝后端并启动
echo
${SETCOLOR_SUCCESS} && echo "-----------------------------------<后端部署>-----------------------------------" && ${SETCOLOR_NORMAL}
rm -rf ${WEBDIR}/* &>/dev/null
\cp -fr ${ORIGINAL}/${CHATDIR}/${SERDIR} ${WEBDIR}
# 检测返回值
if [ $? -eq 0 ]; then
    # 如果指令执行成功，则继续运行下面的操作
    echo "Service Copy Success"
else
    # 如果指令执行不成功，则输出错误日志，并退出脚本
    echo "Copy Error"
    exit 1
fi
# 检查名为 node后端 的进程是否正在运行
pid=$(lsof -t -i:3002)
if [ -z "$pid" ]; then
    echo "后端程序未运行,启动中..."
else
    echo "后端程序正在运行,现在停止程序并更新..."
    kill -9 $pid
fi
\cp -fr ${ORIGINAL}/${CHATDIR}/${FONTDIR}/* ${WEBDIR}
# 检测返回值
if [ $? -eq 0 ]; then
    # 如果指令执行成功，则继续运行下面的操作
    echo "WEB Copy Success"
else
    # 如果指令执行不成功，则输出错误日志，并退出脚本
    echo "Copy Error"
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
        echo "chatgpt-web后端服务已成功启动"
    else
        echo
        echo "ERROR：后端服务端口 3002 未在监听"
        echo
        ${SETCOLOR_RED} && echo "----------------chatgpt-web后端服务启动失败，请查看错误日志 ↓↓↓----------------" && ${SETCOLOR_NORMAL}
        journalctl -u chatgpt-web --no-pager
        ${SETCOLOR_RED} && echo "----------------chatgpt-web后端服务启动失败，请查看错误日志 ↑↑↑----------------" && ${SETCOLOR_NORMAL}
        echo
        exit 3
    fi
else
    echo
    echo "ERROR：后端服务进程未找到"
    echo
    ${SETCOLOR_RED} && echo "----------------chatgpt-web后端服务启动失败，请查看错误日志 ↓↓↓----------------" && ${SETCOLOR_NORMAL}
    journalctl -u chatgpt-web --no-pager
    ${SETCOLOR_RED} && echo "----------------chatgpt-web后端服务启动失败，请查看错误日志 ↑↑↑----------------" && ${SETCOLOR_NORMAL}
    echo
    exit 4
fi


# 拷贝前端刷新Nginx服务
${SETCOLOR_SUCCESS} && echo "-----------------------------------<前端部署>-----------------------------------" && ${SETCOLOR_NORMAL}
if ! nginx -t ; then
    echo "Nginx 配置文件存在错误，请检查配置"
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

echo "公网访问地址: http://$PUBLIC_IP"
echo "内网访问地址: http://$INTERNAL_IP"
}

# 删除源码包文件
function DELSOURCE() {
  rm -rf ${ORIGINAL}/${CHATDIR}
  echo
  ${SETCOLOR_SUCCESS} && echo "--------------------------------------------------------------------------------" && ${SETCOLOR_NORMAL}
  WEBURL
  ${SETCOLOR_SUCCESS} && echo "-----------------------------------<部署完成>-----------------------------------" && ${SETCOLOR_NORMAL}
}

# 添加Nginx后端代理配置
function NGINX_CONF() {
read -e -p "是否修改Nginx配置[y/n](通过本脚本部署的Nginx可选择 y)：" NGCONF
if [ "$NGCONF" = "y" ]; then
   INFO "You chose yes."
   INFO "config：/etc/nginx/conf.d/default.conf"
cat > /etc/nginx/conf.d/default.conf <<\EOF
server {
    listen       80;
    server_name  localhost;

    access_log  /var/log/nginx/host.access.log  main;

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
    CHECK_PKG_MANAGER
    CHECKMEM
    CHECKFIRE
    INSTALL_PACKAGE
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
