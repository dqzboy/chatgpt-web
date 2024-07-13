#!/usr/bin/env bash
#===============================================================================
#
#          FILE: chatnio_install.sh
# 
#         USAGE: ./chatnio_install.sh
#
#   DESCRIPTION: Chat Nio项目一键构建、部署脚本
# 
#  ORGANIZATION: DingQz dqzboy.com 浅时光博客
#===============================================================================

echo
cat << EOF

             ██████╗██╗  ██╗ █████╗ ████████╗███╗   ██╗██╗ ██████╗ 
            ██╔════╝██║  ██║██╔══██╗╚══██╔══╝████╗  ██║██║██╔═══██╗
            ██║     ███████║███████║   ██║   ██╔██╗ ██║██║██║   ██║
            ██║     ██╔══██║██╔══██║   ██║   ██║╚██╗██║██║██║   ██║
            ╚██████╗██║  ██║██║  ██║   ██║   ██║ ╚████║██║╚██████╔╝
             ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═══╝╚═╝ ╚═════╝ 
                                                       
EOF

echo "-------------------------------------------------------------------------------"
echo -e "\033[32m机场推荐\033[0m(\033[34m按量不限时，解锁ChatGPT\033[0m)：\033[34;4mhttps://mojie.mx/#/register?code=CG6h8Irm\033[0m"
echo "-------------------------------------------------------------------------------"
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

# 前端编译完成后需要拷贝的文件存储目录。根据项目情况指定,目前无需变动
FONTDIR="dist"

# 获取执行脚本的当前绝对路径
ORIGINAL=${PWD}

# 定义安装重试次数
attempts=0
maxAttempts=3

INFO "======================= 检查环境 ======================="

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


# OS version
OSVER=$(cat /etc/os-release | grep -o '[0-9]' | head -n 1)

function CHECK_MEM() {
INFO "Checking server memory resources. please wait..."

# 获取内存使用率，并保留两位小数
memory_usage=$(free | awk '/^Mem:/ {printf "%.2f", $3/$2 * 100}')

# 将内存使用率转为整数（去掉小数部分）
memory_usage=${memory_usage%.*}

if [[ $memory_usage -gt 70 ]]; then  # 判断是否超过 70%
    read -e -p "${WARN} Memory usage is higher than 70%($memory_usage%). Do you want to continue? (y/n) " continu
    if [ "$continu" == "n" ] || [ "$continu" == "N" ]; then
        exit 1
    fi
else
    INFO "Memory resources are sufficient. Please continue.($memory_usage%)"
fi
}

function CHECK_FIRE() {
INFO "Firewall && SELinux detection."
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
}

function INSTALL_PACKAGE() {
# 安装软件超时时间,单位秒
TIMEOUT=300
INFO "Installing necessary system components. please wait..."

# 定义要安装的软件包列表
PACKAGES_YUM=("epel-release" "wget" "git" "lsof" "openssl-devel" "zlib-devel" "gd-devel" "pcre-devel" "pcre2")

for package in "${PACKAGES_YUM[@]}"; do
    if $pkg_manager -q "$package" &>/dev/null; then
        echo -e "${WARN} 已经安装 $package ..."
    else
        echo -e "${INFO} 正在安装 $package ..."

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

INFO "System components installation completed."
}


function INSTALL_GOLANG () {
    INFO "=======================安装GOLANG======================="
    # 检查是否已安装golang
    if which go &>/dev/null; then
        INFO "GOLANG is already installed."
    else
        INFO "Installing GOLANG program, please wait..."

        while [ $attempts -lt $maxAttempts ]; do
            $package_manager -y install golang &>/dev/null

            if [ $? -ne 0 ]; then
                ((attempts++))
                WARN "Attempting to install GOLANG >>> (Attempt: $attempts)"

                if [ $attempts -eq $maxAttempts ]; then
                    ERROR "GOLANG installation failed. Please try installing manually."
                    echo "$package_manager -y install golang"
                    exit 1
                fi
            else
                INFO "GOLANG installed."
                break
            fi
        done
    fi
}


function INSTALL_NGINX() {
    INFO "=======================安装NGINX======================="
    # 检查是否已安装Nginx
    if which nginx &>/dev/null; then
        INFO "Nginx is already installed."
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
        INFO "Nginx is already running."
    else
        WARN "Nginx is not running. Attempting to start Nginx..."
        start_attempts=3

        # 最多尝试启动 3 次
        for ((i=1; i<=$start_attempts; i++)); do
            start_nginx
            if pgrep "nginx" > /dev/null; then
                INFO "Nginx has been successfully started."
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
}

function INSTALL_NODEJS() {
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
        
        # 使用不同的包管理工具安装Node.js
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
                    echo "Command：npm install -g pnpm"
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
    packages=("tsc" "rimraf")

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


function INSTALL_REDIS() {
    INFO "=======================安装Redis======================="
    # 安装MYSQL
    start_redis() {
        INFO "Installing Redis program, please wait..."
        $package_manager -y install redis &>/dev/null
        if [ $? -ne 0 ]; then
            ERROR "Redis installation failed. Please try installing manually."
            exit 1
        else
            INFO "Redis installation successful."
        fi
    }

    # 检查 Redis 是否已经安装
    if ! command -v redis-server &> /dev/null; then
        start_redis
    fi

    # 定义一个函数来尝试启动 Redis
    start_redis() {
        systemctl daemon-reexec &>/dev/null
        systemctl enable --now redis &>/dev/null
    }

    # 检查 Redis 是否正在运行
    if systemctl is-active redis >/dev/null 2>&1; then
        INFO "Redis is already running."
    else
        WARN "Redis is not running. Attempting to start Redis..."
        start_attempts=3

        # 最多尝试启动 3 次
        for ((i=1; i<=$start_attempts; i++)); do
            start_redis
            if systemctl is-active redis >/dev/null 2>&1; then
                INFO "Redis has been successfully started."
                break
            else
                if [ $i -eq $start_attempts ]; then
                    ERROR "Redis couldn't start after $start_attempts attempts. Please check the logs."
                    exit 1
                else
                    WARN "Failed to start Redis for the $i time. Retrying..."
                fi
            fi
        done
    fi    
}



function CREATE_MYSQL_DB() {
    # 从日志文件中获取MySQL自动生成的root密码
    mysql_root_password=$(grep 'temporary password' /var/log/mysqld*.log 2>/dev/null | tail -1 | awk '{print $NF}')

    # 提示用户是否要修改root密码
    read -e -p "$(WARN "是否要修改MySQL ROOT密码？[y/n]: ")"  modify_password_choice

    if [[ "$modify_password_choice" == "y" || "$modify_password_choice" == "Y" ]]; then
        # 提示用户输入新的root密码，并进行强度验证
        read -e -p "$(INFO "请输入新的MySQL ROOT密码（必须包括大小写字母+数字+特殊字符且长度为8位以上: ")"  new_mysql_pwd
        read -e -p "$(INFO "请输入旧的MySQL ROOT密码（新数据库临时密码为：${mysql_root_password}）: ")" old_mysql_pwd

        # 将新密码存储在变量中
        MYSQL_PWD=$new_mysql_pwd

        # 尝试使用新密码更新MySQL ROOT密码，并捕获输出
        mysql_error=$(mysql --connect-expired-password -u root -p"$old_mysql_pwd" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_PWD';" 2>&1)

        # 检查mysql命令的退出状态码
        if [ $? -eq 0 ]; then
            INFO "MySQL ROOT密码已成功更新为：$MYSQL_PWD"
        else
            ERROR "MySQL ROOT密码更新失败。错误信息：$mysql_error"
            exit 1
        fi
    else
        WARN "跳过修改MySQL ROOT密码,请手动输入MySQL ROOT用户密码"
        read -e -p "$(INFO "请输入MySQL ROOT密码: ")" $MYSQL_PWD
    fi

    # 检查用户是否要创建数据库
    read -e -p "$(INFO "是否创建数据库？[y/n]: ")" create_db_choice 

    if [[ "$create_db_choice" == "y" || "$create_db_choice" == "Y" ]]; then
        read -e -p "$(INFO "请输入数据库名称(不能包含连字符 - ): ")" DB_NAME 

        # 检查数据库是否存在
        mysql --connect-expired-password -u root -p"$MYSQL_PWD" -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$DB_NAME';" 2>/dev/null | grep -q "$DB_NAME"

        if [ $? -eq 0 ]; then
            WARN "数据库 '$DB_NAME' 已存在。"
        else
            # 数据库不存在，创建数据库
            mysql_error=$(mysql --connect-expired-password -u root -p"$MYSQL_PWD" -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>&1) 
            # 检查mysql命令的退出状态码
            if [ $? -eq 0 ]; then
                INFO "数据库 '$DB_NAME' 创建完成。"
            else
                ERROR "数据库 '$DB_NAME' 创建失败,错误信息：$mysql_error"
                exit 1
            fi
        fi
    else
        WARN "跳过创建数据库。"
        read -e -p "$(INFO "请输入数据库名称(不能包含连字符 - ): ")" DB_NAME 
    fi
}

function INSTALL_MYSQL() {
    INFO "=======================安装MYSQL======================="
    down_mysql() {
        # 不管是否存在安装包都执行下删除命令
        rm -f mysql-community-* &>/dev/null
        #定义安装版本
        mysqlVer=8.2.0-1
        wget https://cdn.mysql.com/archives/mysql-${mysqlVer:0:3}/mysql-community-common-${mysqlVer}.el$(rpm -E %{rhel}).x86_64.rpm
        wget https://cdn.mysql.com/archives/mysql-${mysqlVer:0:3}/mysql-community-libs-${mysqlVer}.el$(rpm -E %{rhel}).x86_64.rpm
        wget https://cdn.mysql.com/archives/mysql-${mysqlVer:0:3}/mysql-community-devel-${mysqlVer}.el$(rpm -E %{rhel}).x86_64.rpm
        wget https://cdn.mysql.com/archives/mysql-${mysqlVer:0:3}/mysql-community-client-${mysqlVer}.el$(rpm -E %{rhel}).x86_64.rpm
        wget https://cdn.mysql.com/archives/mysql-${mysqlVer:0:3}/mysql-community-server-${mysqlVer}.el$(rpm -E %{rhel}).x86_64.rpm
        wget https://cdn.mysql.com/archives/mysql-${mysqlVer:0:3}/mysql-community-client-plugins-${mysqlVer}.el$(rpm -E %{rhel}).x86_64.rpm
        wget https://cdn.mysql.com/archives/mysql-${mysqlVer:0:3}/mysql-community-icu-data-files-${mysqlVer}.el$(rpm -E %{rhel}).x86_64.rpm
    }
    # 安装MYSQL
    start_mysql() {
        INFO "Installing MySQL program, please wait..."
        down_mysql &>/dev/null
        $package_manager -y install mysql-community-* &>/dev/null
        if [ $? -ne 0 ]; then
            ERROR "MySQL installation failed. Please try installing manually."
            exit 1
        else
            INFO "MySQL installation successful."
            rm -f mysql-community-* &>/dev/null
        fi
    }

    # 检查 MySQL 是否已经安装
    if ! command -v mysqld &> /dev/null; then
        start_mysql
    fi

    # 定义一个函数来尝试启动 MySQL
    start_mongodb() {
        systemctl daemon-reexec &>/dev/null
        systemctl enable --now mysqld &>/dev/null
    }

    # 检查 MySQL 是否正在运行
    if systemctl is-active mysqld >/dev/null 2>&1; then
        INFO "MySQL is already running."
        CREATE_MYSQL_DB
    else
        WARN "MySQL is not running. Attempting to start MySQL..."
        start_attempts=3

        # 最多尝试启动 3 次
        for ((i=1; i<=$start_attempts; i++)); do
            start_mongodb
            if systemctl is-active mysqld >/dev/null 2>&1; then
                INFO "MySQL has been successfully started."
                CREATE_MYSQL_DB
                break
            else
                if [ $i -eq $start_attempts ]; then
                    ERROR "MySQL couldn't start after $start_attempts attempts. Please check the logs."
                    exit 1
                else
                    WARN "Failed to start MySQL for the $i time. Retrying..."
                fi
            fi
        done
    fi    
}


function GITCLONE() {
    INFO "======================= 开始安装 ======================="
    rm -rf chatnio* &>/dev/null
    CHATNIO="https://github.com/Deeptrain-Community/chatnio"

    INFO  "请选择要克隆的仓库："
    echo "-------------------------------------------------"
    echo "1. Deeptrain-Community/chatnio"
    echo "-------------------------------------------------"

    for i in {1..2}; do
        read -e -n1 inputgpt
        case $inputgpt in
            1) repository=$CHATNIO; CHATDIR=chatnio; break;;
            *) ERROR "Invalid option, please retry.";;
        esac

        if [ $i -eq 2 ]; then
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
		            # 国内服务器使用代理加速 git 克隆
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
WARN "构建之前请先指定Nginx根路径!"

# 交互输入Nginx根目录(提前进行创建好)
if [ -f .input ]; then
  last_input=$(cat .input)
  read -e -p "$(INFO "Chat Nio存储绝对路径[上次记录：${last_input} 回车用上次记录]: ")" WEBDIR
  if [ -z "${WEBDIR}" ];then
      WEBDIR="$last_input"
      INFO "Chat Nio 存储路径：${WEBDIR}"
  else
      INFO "Chat Nio 存储路径：${WEBDIR}"
  fi
else
  read -e -p "WEB存储绝对路径(回车默认Nginx路径)：" WEBDIR
  if [ -z "${WEBDIR}" ];then
      WEBDIR="/usr/share/nginx/html"
      INFO "Chat Nio 存储路径：${WEBDIR}"
  else
      INFO "Chat Nio 存储路径：${WEBDIR}"
  fi
fi
echo "${WEBDIR}" > .input
}

# 定义前后端构建函数，下面BUILD函数调用
function BUILDWEB() {
INFO "《前端构建中,请稍等...执行过程中请勿进行操作》"

# 安装依赖
pnpm install 2>&1 >/dev/null | grep -E "ERROR|FAIL|WARN"
# 打包
pnpm build | grep -E "ERROR|ELIFECYCLE|WARN|*built in*"
}

function BUILDSEV() {
INFO "《后端构建中,请稍等...执行过程中请勿进行操作》"
# 构建
go build -o chatnio 2>&1 >/dev/null | grep -E "ERROR|FAIL|WARN"
}


function BUILD() {
INFO "======================= 构建前端 ======================="
# 定义前端构建目录
# CHATDIR就是项目的名称chatnio
APPDIR="${CHATDIR}/app"
# 拷贝.env配置替换
if [ ! -f "${ORIGINAL}/env.example" ]; then
    ERROR "File 'env.example' not found. Please make sure it exists."
    exit 1
fi
cp "${ORIGINAL}/env.example" "${ORIGINAL}/${APPDIR}/.env.deeptrain"

# 修改默认暗黑模式为亮色模式
#sed -i "s#dark#light#g" ${ORIGINAL}/${APPDIR}/src/components/ThemeProvider.tsx

# 进入到前端目录下
cd ${ORIGINAL}/${APPDIR} && BUILDWEB
directory="${ORIGINAL}/${APPDIR}/${FONTDIR}"
if [ ! -d "$directory" ]; then
    ERROR "Frontend build failed..."
    exit 1
fi
INFO
INFO "======================= 构建后端 ======================="
# 进入到后端目录下
cd ${ORIGINAL}/${CHATDIR} && BUILDSEV
}

# 用来处理新环境部署还是更新服务
function DEPLOY_CONFIG() {
# 定义后端配置存放目录和文件名称
CONFIG_DIR="config"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"

#检查文件是否存在
if [ -f "${ORIGINAL}/${CONFIG_FILE}" ]; then
    INFO "File ${CONFIG_FILE} exists."
else
    ERROR "File ${CONFIG_FILE} does not exist."
    exit 1
fi

# 修改后端的mysql数据库confit.yaml配置 
sed  -i "s#PASSWD#${MYSQL_PWD}#g"  ${ORIGINAL}/${CONFIG_FILE}
sed  -i "s#DBNAME#${DB_NAME}#g"  ${ORIGINAL}/${CONFIG_FILE}

#检查目录是否存在
if [ -d "${ORIGINAL}/${CONFIG_DIR}" ]; then
    INFO "Directory ${CONFIG_DIR} exists."
else
    ERROR "Directory ${CONFIG_DIR} does not exist."
    exit 1
fi

# 拷贝当前目录下的配置文件到项目部署目录下
\cp -fr ${ORIGINAL}/${CONFIG_DIR} ${WEBDIR}
}


# 拷贝构建成品到Nginx网站根目录
function DEPLOY_SERVER() {
# 拷贝后端并启动
INFO "======================= 开始部署 ======================="
if [ -f ${ORIGINAL}/.choice ]; then
    last_choice=$(cat ${ORIGINAL}/.choice)
    read -e -p "$(echo -e ${INFO} ${GREEN}"新装 or 更新? [1/2] [上次记录：${last_choice} 回车用上次记录]："${RESET})" choice_install
    if [ -z "${choice_install}" ];then
        choice_install="$last_choice"
        INFO "选择：${choice_install}"
    else
        INFO "选择：${choice_install}"
    fi
else
    read -e -p "$(echo -e ${INFO} ${GREEN}"新装 or 更新? [1/2]: "${RESET})" choice_install
    if [ -z "${choice_install}" ];then
        choice_install="1"
        INFO "选择：${choice_install}"
    else
        INFO "选择：${choice_install}"
    fi
fi

echo "${choice_install}" > ${ORIGINAL}/.choice

if [ "$choice_install" == "1" ]; then
    rm -rf ${WEBDIR}/* &>/dev/null
    DEPLOY_CONFIG
elif [ "$choice_install" == "2" ]; then
    find "${WEBDIR}" -mindepth 1 -maxdepth 1 ! -name "config" -exec rm -rf {} +
else
    INFO "请输入 '1' 表示安装，或者 '2' 表示更新"
fi

# 定义前端构建目录.CHATDIR就是项目的名称chatnio
APPDIR="${CHATDIR}/app"
UTILSDIR="${CHATDIR}/utils"

# go编译完成的执行文件名称
EXE_FILE="chatnio"

# 拷贝构建完成的后端执行文件和配置过去
\cp -fr ${ORIGINAL}/${CHATDIR}/${EXE_FILE} ${WEBDIR}
# 检测返回值
if [ $? -eq 0 ]; then
    # 如果指令执行成功，则继续运行下面的操作
    INFO "Backend service deployment was successful"
else
    # 如果指令执行不成功，则输出错误日志，并退出脚本
    ERROR "Backend service deployment failed"
    exit 1
fi

# 检查后端进程是否正在运行
pid=$(lsof -t -i:8094)
if [ -z "$pid" ]; then
    INFO "Backend service not running, starting up..."
else
    INFO "The backend service is running, now stop the program and update..."
    kill -9 $pid
fi

# 拷贝前端构建完成的文件到Nginx托管目录下
\cp -fr ${ORIGINAL}/${UTILSDIR} ${WEBDIR}
# 检测返回值
if [ $? -eq 0 ]; then
    # 如果指令执行成功，则继续运行下面的操作
    INFO "Front-end service deployment was successful（utils）"
else
    # 如果指令执行不成功，则输出错误日志，并退出脚本
    ERROR "Front-end service deployment failed"
    exit 2
fi

\cp -fr ${ORIGINAL}/${APPDIR} ${WEBDIR}
# 检测返回值
if [ $? -eq 0 ]; then
    # 如果指令执行成功，则继续运行下面的操作
    INFO "Front-end service deployment was successful（app）"
else
    # 如果指令执行不成功，则输出错误日志，并退出脚本
    ERROR "Front-end service deployment failed"
    exit 2
fi

# 添加开机自启
cat > /etc/systemd/system/chatnio.service <<EOF
[Unit]
Description=Chat Nio Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${WEBDIR}
ExecStart=${WEBDIR}/chatnio
Restart=always
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
TimeoutStopSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl restart chatnio.service
systemctl enable chatnio.service &>/dev/null

sleep 10
if pgrep -x "chatnio" > /dev/null
then
    # 检测端口是否正在监听
    if ss -tuln | grep ":8094" > /dev/null
    then
        INFO "Chat Nio 后端服务已成功启动"
    else
        ERROR "Chat Nio 后端服务端口 8094 未在监听"
        ERROR "-----------Chat Nio 后端服务启动失败，请查看错误日志 ↓↓↓-----------"
          journalctl -u chatnio.service --no-pager
        ERROR "-----------Chat Nio 后端服务启动失败，请查看错误日志 ↑↑↑-----------"
        exit 3
    fi
else

    ERROR "Chat Nio 后端服务进程未找到"
    ERROR "-----------Chat Nio 后端服务启动失败，请查看错误日志 ↓↓↓-----------"
      journalctl -u chatnio.service --no-pager
    ERROR "-----------Chat Nio 后端服务启动失败，请查看错误日志 ↑↑↑-----------"
    echo
    exit 4
fi


# 拷贝前端刷新Nginx服务
if ! nginx -t ; then
    ERROR "ChatNio Nginx 配置文件存在错误，请检查配置"
    exit 5
else
    nginx -s reload
fi
}

function WEBURL(){
# 获取公网IP
PUBLIC_IP=$(curl -s ip.sb)

# 获取所有网络接口的IP地址
ALL_IPS=$(hostname -I)

# 排除不需要的地址（127.0.0.1和docker0）
INTERNAL_IP=$(echo "$ALL_IPS" | awk '$1!="127.0.0.1" && $1!="::1" && $1!="docker0" {print $1}')

INFO "请用浏览器访问面板: "
INFO "公网访问地址: http://$PUBLIC_IP"
INFO "内网访问地址: http://$INTERNAL_IP"
INFO "管理员账号密码: root｜chatnio123456"
INFO
INFO "作者博客: https://dqzboy.com"
INFO "技术交流: https://t.me/dqzboyblog"
INFO "代码仓库: https://github.com/dqzboy/chatgpt-web"
INFO  
INFO "如果使用的是云服务器，请至安全组开放 80 端口"
INFO
}

# 添加Nginx后端代理配置
function NGINX_CONF() {
read_attempts=0
while true; do
    read -e -p "是否修改Nginx配置[y/n](通过本脚本部署的Nginx可选择 y)：" NGCONF
    if [ "$NGCONF" = "y" ]; then
        INFO "You chose yes."
        INFO "config：/etc/nginx/conf.d/default.conf"
        cat > /etc/nginx/conf.d/default.conf <<\EOF
server {
    listen       80;
    server_name  localhost;

    location / {
        proxy_pass http://127.0.0.1:8094;
        proxy_set_header Host 127.0.0.1:$server_port;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header REMOTE-HOST $remote_addr;
        add_header X-Cache $upstream_cache_status;
        proxy_set_header X-Host $host:$server_port;
        proxy_set_header X-Scheme $scheme;
        proxy_connect_timeout 30s;
        proxy_read_timeout 86400s;
        proxy_send_timeout 30s;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF
        break
    elif [ "$NGCONF" = "n" ]; then
        WARN "You chose no."
        break
    else
        ERROR "Invalid parameter. Please enter 'y' or 'n'."
        read_attempts=$((read_attempts+1))
        if [ "$read_attempts" -eq 3 ]; then
            ERROR "Maximum number of attempts reached. Exiting."
            exit 1
        fi
    fi
done
}

# 删除源码包文件,并调用最后的作者提示信息
function DELSOURCE() {
  rm -rf ${ORIGINAL}/${CHATDIR}
  INFO
  INFO "=================感谢您的耐心等待，安装已经完成=================="
  INFO
    WEBURL
  INFO "================================================================"
}

function main() {
    CHECK_PACKAGE_MANAGER
    CHECK_PKG_MANAGER
    CHECK_MEM
    CHECK_FIRE
    
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
    
    INSTALL_GOLANG
    INSTALL_NGINX
    INSTALL_NODEJS
    INSTALL_REDIS

    while true; do
        read -e -p "$(echo -e ${INFO} ${GREEN}"是否执行MySQL安装? [y/n]: "${RESET})" choice_package
        case "$choice_package" in
            y|Y )
                INSTALL_MYSQL
                break;;
            n|N )
                WARN "跳过MySQL数据库安装,请手动指定数据库名称和MySQL ROOT 密码"
                read -e -p "$(INFO "请输入连接的数据库名称: ")" DB_NAME
                read -e -p "$(INFO "请输入数据库Root密码: ")" MYSQL_PWD
                break;;
            * )
                INFO "请输入 'y' 表示是，或者 'n' 表示否。";;
        esac
    done
    
    GITCLONE
    WEBINFO
    BUILD
    DEPLOY_SERVER
    NGINX_CONF
    DELSOURCE
}
main
