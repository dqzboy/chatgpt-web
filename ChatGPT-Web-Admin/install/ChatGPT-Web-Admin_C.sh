#!/usr/bin/env bash
#===============================================================================
#
#          FILE: ChatGPT-Web-Admin_C.sh
# 
#         USAGE: ./ChatGPT-Web-Admin_C.sh
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

SUCCESS() {
  ${SETCOLOR_SUCCESS} && echo "------------------------------------< $1 >-------------------------------------"  && ${SETCOLOR_NORMAL}
}

SUCCESS1() {
  ${SETCOLOR_SUCCESS} && echo " $1 "  && ${SETCOLOR_NORMAL}
}

ERROR() {
  ${SETCOLOR_RED} && echo " $1 "  && ${SETCOLOR_NORMAL}
}

INFO() {
  ${SETCOLOR_SKYBLUE} && echo " $1 "  && ${SETCOLOR_NORMAL}
}

WARN() {
  ${SETCOLOR_YELLOW} && echo " $1 "  && ${SETCOLOR_NORMAL}
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
OSVER=$(cat /etc/centos-release | grep -o '[0-9]' | head -n 1)

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
      dnf -y install ${NGINX} &>/dev/null
      if [ $? -ne 0 ]; then
        WARN "安装失败，请手动安装，安装成功之后再次执行脚本！"
        echo " 命令：wget http://nginx.org/packages/centos/${OSVER}/x86_64/RPMS/${NGINX} && yum -y install ${NGINX}"
        exit 1
      else
        INFO "Nginx installed."
        rm -f ${NGINX}
      fi
  elif [ "$OSVER" = "7" ]; then
      # 下载并安装RPM包
      yum -y install wget git openssl-devel pcre-devel zlib-devel gd-devel &>/dev/null
      yum -y install pcre2 &>/dev/null
      rm -f ${NGINX}
      wget http://nginx.org/packages/centos/${OSVER}/x86_64/RPMS/${NGINX} &>/dev/null
      yum -y install ${NGINX} &>/dev/null
      if [ $? -ne 0 ]; then
        WARN "安装失败，请手动安装，安装成功之后再次执行脚本！"
        echo " 命令：wget http://nginx.org/packages/centos/${OSVER}/x86_64/RPMS/${NGINX} && yum -y install ${NGINX}"
        exit 1
      else
        echo "Nginx installed."
        rm -f ${NGINX}
      fi
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
        curl -fsSL https://rpm.nodesource.com/setup_16.x | bash - &>/dev/null
        dnf install -y nodejs &>/dev/null
    elif [ "$OSVER" = "7" ]; then
        yum -y install libstdc++.so.glibc glibc lsof &>/dev/null
        curl -fsSL https://rpm.nodesource.com/setup_16.x | bash - &>/dev/null
        yum install -y nodejs &>/dev/null
    else
        ERROR "Unsupported OS version: $OSVER"
        exit 1
    fi
else
    INFO "Node.js 已安装..."
fi

# 检查是否安装了 pnpm
if ! command -v pnpm &> /dev/null
then
    WARN "pnpm 未安装，正在进行安装..."
    # 安装 pnpm
    npm install -g pnpm &>/dev/null
else
    INFO "pnpm 已安装..." 
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
    yum install -y mongodb-org &>/dev/null
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
        1) git clone $repository; break;;
        2) git clone https://ghproxy.com/$repository; break;;
        *) ERROR "无效的选项，请重试";;
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
    CHECKFIRE
    GITCLONE
    INSTALL_NGINX
    NODEJS
    REPO
    BUILD
    NGINX
    DELSOURCE
}
main
