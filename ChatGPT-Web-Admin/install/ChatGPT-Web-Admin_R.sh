#!/usr/bin/env bash
#===============================================================================
#
#          FILE: ChatGPT-Web-Admin_R.sh
# 
#         USAGE: ./ChatGPT-Web-Admin_R.sh
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

# 定义需要拷贝的文件目录
CHATDIR="chatgpt-web"
SERDIR="service"
FONTDIR="dist"
ORIGINAL=${PWD}

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
OSVER=$(cat /etc/redhat-release | grep -o '[0-9]' | head -n 1)

function CHECKMEM() {
INFO "Checking server memory resources. Please wait."
if ! command -v bc &> /dev/null; then
    while [ $attempts -lt $maxAttempts ]; do
        yum install -y bc lsof &>/dev/null
        if [ $? -ne 0 ]; then
            ((attempts++))
            WARN "尝试安装内存计算工具 (Attempt: $attempts)"

            if [ $attempts -eq $maxAttempts ]; then
                ERROR "内存计算工具安装失败，请尝试手动执行安装。"
                echo "命令：dnf install -y bc"
                exit 1
            fi
        else
            break
        fi
    done
fi
total=$(free -m | awk 'NR==2{print $2}')  # 获取总内存数
used=$(free -m | awk 'NR==2{print $3}')   # 获取已使用的内存数
rate=$(echo "scale=2; $used/$total*100" | bc)  # 计算内存使用率

if [[ $(echo "$rate > 70.0" | bc -l) -eq 1 ]]; then  # 判断是否超过 70%
    read -p "Warning: Memory usage is higher than 70%. Do you want to continue? (y/n) " continu
    if [ "$continu" == "n" ] || [ "$continu" == "N" ]; then
        exit 1
    fi
else
    SUCCESS1 "Memory resources are sufficient. Please continue."
fi
DONE
}

function CHECKFIRE() {
SUCCESS "Firewall && SELinux detection."
# Check if firewall is enabled
firewall_status=$(systemctl is-active firewalld)
if [[ $firewall_status == 'active' ]]; then
    # If firewall is enabled, disable it
    systemctl stop firewalld
    systemctl disable firewalld
    INFO "Firewall has been disabled."
else
    INFO "Firewall is already disabled."
fi

# Check if SELinux is enforcing
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

function INSTALL_NGINX() {
SUCCESS "Nginx detection and installation."
# 检查是否已安装Nginx
if which nginx &>/dev/null; then
  INFO "Nginx is already installed."
else
  SUCCESS1 "Installing Nginx..."
  NGINX="nginx-1.24.0-1.el${OSVER}.ngx.x86_64.rpm"
  if [ "$OSVER" = "8" ]; then
      # 下载并安装RPM包
      dnf -y install wget git openssl-devel pcre-devel zlib-devel gd-devel &>/dev/null
      dnf -y install pcre2 &>/dev/null
      rm -f ${NGINX}
      wget http://nginx.org/packages/centos/${OSVER}/x86_64/RPMS/${NGINX} &>/dev/null
      while [ $attempts -lt $maxAttempts ]; do
          dnf -y install ${NGINX} &>/dev/null
          if [ $? -ne 0 ]; then
              ((attempts++))
              WARN "尝试安装Nginx (Attempt: $attempts)"

              if [ $attempts -eq $maxAttempts ]; then
                  ERROR "Nginx安装失败，请尝试手动执行安装。"
	          rm -f ${NGINX}
                  echo "命令：wget http://nginx.org/packages/centos/${OSVER}/x86_64/RPMS/${NGINX} && dnf -y install ${NGINX}"
                  exit 1
              fi
          else
              INFO "Nginx installed."
              rm -f ${NGINX}
              break
          fi
      done
  elif [ "$OSVER" = "9" ]; then
      # 下载并安装RPM包
      dnf -y install wget git openssl-devel pcre-devel zlib-devel gd-devel &>/dev/null
      dnf -y install pcre2 &>/dev/null
      rm -f ${NGINX}
      wget http://nginx.org/packages/centos/${OSVER}/x86_64/RPMS/${NGINX} &>/dev/null
      while [ $attempts -lt $maxAttempts ]; do
          dnf -y install ${NGINX} &>/dev/null
          if [ $? -ne 0 ]; then
              ((attempts++))
              WARN "尝试安装Nginx (Attempt: $attempts)"

              if [ $attempts -eq $maxAttempts ]; then
                  ERROR "Nginx安装失败，请尝试手动执行安装。"
                  rm -f ${NGINX}
                  echo "命令：wget http://nginx.org/packages/centos/${OSVER}/x86_64/RPMS/${NGINX} && dnf -y install ${NGINX}"
                  exit 1
              fi
          else
              INFO "Nginx installed."
              rm -f ${NGINX}
              break
          fi
      done
  else
    ERROR "Unsupported OS version: $OSVER"
    exit 1
  fi
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
DONE
}

function NODEJS() {
SUCCESS "Node.js detection and installation."
# 检查是否安装了Node.js
if ! command -v node &> /dev/null;then
    ERROR "Node.js 未安装，正在进行安装..."
    # 安装 Node.js
    if [ "$OSVER" = "8" ]; then
        dnf -y install libstdc++.so.glibc glibc lsof &>/dev/null
        curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash - &>/dev/null
	if [ $? -ne 0 ]; then
	    ERROR "NodeJS安装失败！"
	    exit 1
	fi
        while [ $attempts -lt $maxAttempts ]; do
            dnf install -y nodejs &>/dev/null
            if [ $? -ne 0 ]; then
                ((attempts++))
                WARN "尝试安装NodeJS (Attempt: $attempts)"

                if [ $attempts -eq $maxAttempts ]; then
                    ERROR "NodeJS安装失败，请尝试手动执行安装。"
                    echo " 命令：dnf install -y nodejs"
                    exit 1
                fi
            else
                INFO "NodeJS installed."
                break
            fi
        done
    elif [ "$OSVER" = "9" ]; then
        dnf -y install libstdc++.so.glibc glibc lsof &>/dev/null
        curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash - &>/dev/null
        if [ $? -ne 0 ]; then
            ERROR "NodeJS安装失败！"
            exit 1
        fi
        while [ $attempts -lt $maxAttempts ]; do
            dnf install -y nodejs &>/dev/null
            if [ $? -ne 0 ]; then
                ((attempts++))
                WARN "尝试安装NodeJS (Attempt: $attempts)"

                if [ $attempts -eq $maxAttempts ]; then
                    ERROR "NodeJS安装失败，请尝试手动执行安装。"
                    echo " 命令：dnf install -y nodejs"
                    exit 1
                fi
            else
                INFO "NodeJS installed."
                break
            fi
        done
    else
        ERROR "Unsupported OS version: $OSVER"
        exit 1
    fi
else
    INFO "Node.js Installed..."
fi

# 检查是否安装了 pnpm
if ! command -v pnpm &> /dev/null
then
    WARN "pnpm 未安装，正在进行安装..."
    # 安装 pnpm
    while [ $attempts -lt $maxAttempts ]; do
        npm install -g pnpm &>/dev/null
        if [ $? -ne 0 ]; then
            ((attempts++))
            WARN "尝试安装pnpm (Attempt: $attempts)"

            if [ $attempts -eq $maxAttempts ]; then
                ERROR "pnpm安装失败，请尝试手动执行安装。"
                echo " 命令：npm install -g pnpm"
                exit 1
            fi
        else
            INFO "pnpm installed."
            break
        fi
    done
else
    INFO "pnpm Installed..." 
fi
DONE
}


function MONGO_USER() {
# 检查用户是否要创建 MongoDB 用户
read -e -p "是否创建 MongoDB 用户？[y/n] " choice
case "$choice" in
  y|Y )
    read -e -p "请输入 MongoDB 用户名：" MONGODB_USERNAME
    read -e -s -p "请输入 MongoDB 密码：" MONGODB_PASSWORD
    echo
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
if [ ! -f /etc/yum.repos.d/mongodb-org-6.0.repo ]; then
cat > /etc/yum.repos.d/mongodb-org-6.0.repo <<\EOF
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF
    while [ $attempts -lt $maxAttempts ]; do
        dnf install -y mongodb-org &>/dev/null
        if [ $? -ne 0 ]; then
            ((attempts++))
            WARN "尝试安装mongodb (Attempt: $attempts)"

            if [ $attempts -eq $maxAttempts ]; then
                ERROR "mongodb安装失败，请尝试手动执行安装。"
                echo " 命令：dnf install -y mongodb-org"
                exit 1
            fi
        else
            INFO "MongoDB installed."
            break
        fi
    done
fi

# 启动 MongoDB 服务
if systemctl is-active mongod >/dev/null 2>&1; then
    INFO "MongoDB 已启动"
    MONGO_USER
else
    systemctl enable --now mongod &>/dev/null
    if systemctl is-active mongod >/dev/null 2>&1; then
        INFO "MongoDB 启动成功"
        MONGO_USER
    else
        ERROR "MongoDB 启动失败"
        exit 1
    fi
fi
DONE
}

function GITCLONE() {
SUCCESS "项目克隆"
CGPTWEB="https://github.com/Chanzhaoyu/chatgpt-web"
KGPTWEB="https://github.com/Kerwin1202/chatgpt-web"

${SETCOLOR_RED} && echo "请选择要克隆的仓库：" && ${SETCOLOR_NORMAL}
echo "1. Chanzhaoyu/chatgpt-web[不带用户中心]"
echo "2. Kerwin1202/chatgpt-web[带用户中心]"

while true; do
    read -n1 input
    case $input in
        1) repository=$CGPTWEB; break;;
        2) repository=$KGPTWEB; break;;
        *) ERROR "无效的选项，请重试";;
    esac
done
echo 
${SETCOLOR_RED} && echo "请选择您的服务器网络环境：" && ${SETCOLOR_NORMAL}
echo "1. 国外"
echo "2. 国内"
while true; do
    read -n1 input
    case $input in
        1)
            if git clone $repository; then
                break
            else
                ERROR "git clone 失败，请重试"
                exit 1
            fi
            ;;
        2)
            if git clone https://ghproxy.com/$repository; then
                break
            else
                ERROR "git clone 失败，请重试"
                exit 2
            fi
            ;;
        *)
            ERROR "无效的选项，请重试"
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
      # 删除配置里面的GitHub相关信息内容(可选，建议保留，尊重项目作者成果)
      #sed -i '/<div class="p-2 space-y-2 rounded-md bg-neutral-100 dark:bg-neutral-700">/,/<\/div>/d' ${ORIGINAL}/${CHATDIR}/src/components/common/Setting/About.vue
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
      # 删除配置里面的GitHub相关信息内容(可选，建议保留，尊重项目作者成果)
      #sed -i '/<div class="p-2 space-y-2 rounded-md bg-neutral-100 dark:bg-neutral-700">/,/<\/div>/d' ${ORIGINAL}/${CHATDIR}/src/components/common/Setting/About.vue
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
      # 删除配置里面的GitHub相关信息内容(可选，建议保留，尊重项目作者成果)
      #sed -i '/<div class="p-2 space-y-2 rounded-md bg-neutral-100 dark:bg-neutral-700">/,/<\/div>/d' ${ORIGINAL}/${CHATDIR}/src/components/common/Setting/About.vue
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
INFO "《前端构建中，请稍等...》"
# 安装依赖
pnpm bootstrap 2>&1 >/dev/null | grep -E "error|fail|warning"
# 打包
pnpm build | grep -E "ERROR|ELIFECYCLE|WARN|*built in*"
}

function BUILDSEV() {
INFO "《后端构建中，请稍等...》"
# 安装依赖
pnpm install 2>&1 >/dev/null | grep -E "error|fail|warning"
# 打包
pnpm build | grep -E "ERROR|ELIFECYCLE|WARN|*Build success*"
}


function BUILD() {
SUCCESS "开始进行构建.构建快慢取决于你的环境"

# 拷贝.env配置替换
cp ${ORIGINAL}/env.example ${ORIGINAL}/${CHATDIR}/${SERDIR}/.env
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

# 删除源码包文件
function DELSOURCE() {
  rm -rf ${ORIGINAL}/${CHATDIR}
  echo
  ${SETCOLOR_SUCCESS} && echo "--------------------------------------------------------------------------------" && ${SETCOLOR_NORMAL}
  echo "访问网站：http://your_vps_ip:80"
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
    WEBTITLE
fi
}

function main() {
    CHECKMEM
    CHECKFIRE
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
