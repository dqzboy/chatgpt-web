#!/usr/bin/env bash
#===============================================================================
#
#          FILE: ChatGPT-Next-Web_C.sh
# 
#         USAGE: ./ChatGPT-Next-Web_C.sh
#
#   DESCRIPTION: ChatGPT-Next-Web项目一键构建、部署、升级更新脚本
# 
#  ORGANIZATION: DingQz dqzboy.com 浅时光博客
#===============================================================================

SETCOLOR_SKYBLUE="echo -en \\E[1;36m"
SETCOLOR_SUCCESS="echo -en \\E[0;32m"
SETCOLOR_NORMAL="echo  -en \\E[0;39m"
SETCOLOR_RED="echo  -en \\E[0;31m"
SETCOLOR_YELLOW="echo -en \\E[1;33m"
GREEN="\033[1;32m"
RESET="\033[0m"
PURPLE="\033[35m"

# 定义项目仓库地址
GITGPT="https://github.com/Yidadaa/ChatGPT-Next-Web"
# 定义需要拷贝的文件目录
CHATDIR="ChatGPT-Next-Web"
ORIGINAL=${PWD}

# Attempts to install
maxAttempts=3
attempts=0

echo
cat << EOF
         ██████╗ ██████╗ ████████╗    ███╗   ██╗███████╗██╗  ██╗████████╗    ██╗    ██╗███████╗██████╗ 
        ██╔════╝ ██╔══██╗╚══██╔══╝    ████╗  ██║██╔════╝╚██╗██╔╝╚══██╔══╝    ██║    ██║██╔════╝██╔══██╗
        ██║  ███╗██████╔╝   ██║       ██╔██╗ ██║█████╗   ╚███╔╝    ██║       ██║ █╗ ██║█████╗  ██████╔╝
        ██║   ██║██╔═══╝    ██║       ██║╚██╗██║██╔══╝   ██╔██╗    ██║       ██║███╗██║██╔══╝  ██╔══██╗
        ╚██████╔╝██║        ██║       ██║ ╚████║███████╗██╔╝ ██╗   ██║       ╚███╔███╔╝███████╗██████╔╝
         ╚═════╝ ╚═╝        ╚═╝       ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝   ╚═╝        ╚══╝╚══╝ ╚══════╝╚═════╝ 
EOF

echo "----------------------------------------------------------------------------------------------------------"
echo
echo -e "\033[32m机场推荐\033[0m(\033[34m按量不限时，解锁ChatGPT\033[0m)：\033[34;4mhttps://mojie.mx/#/register?code=CG6h8Irm\033[0m"
echo

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

function CHECKFIRE() {
SUCCESS "Firewall && SELinux detection."
# Check if firewall is enabled
firewall_status=$(systemctl is-active firewalld)
if [[ $firewall_status == 'active' ]]; then
    # If firewall is enabled, disable it
    systemctl stop firewalld
    systemctl disable firewalld
    SUCCESS1 "Firewall has been disabled."
else
    INFO "Firewall is already disabled."
fi

# Check if SELinux is enforcing
if sestatus | grep "SELinux status" | grep -q "enabled"; then
    WARN "SELinux is enabled. Disabling SELinux..."
    setenforce 0
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    SUCCESS1 "SELinux is already disabled."
else
    INFO "SELinux is already disabled."
fi
}

function GITCLONE() {
SUCCESS "Verify the operational status of the service."
# 检查服务进程是否正在运行
pid=$(lsof -t -i:3000)
if [ -z "$pid" ]; then
    echo "后端程序未运行"
    if [ -d "${ORIGINAL}/${CHATDIR}" ]; then
       rm -rf ${ORIGINAL}/${CHATDIR}
    fi
else
    echo "后端程序正在运行,现在停止程序并更新..."
    kill -9 $pid
    if [ -d "${ORIGINAL}/${CHATDIR}" ]; then
       rm -rf ${ORIGINAL}/${CHATDIR}
    fi
fi

SUCCESS "Acquire the source code of the project."
WARN "                           注: 国内服务器请选择参数 2 "
${SETCOLOR_NORMAL}

read -e -p "$(echo -e ${GREEN}"请选择你的服务器网络环境[国外1/国内2]： "${RESET})" NETWORK
if [ ${NETWORK} == 1 ];then
    cd ${ORIGINAL} && git clone ${GITGPT}
elif [ ${NETWORK} == 2 ];then
    cd ${ORIGINAL} && git clone https://ghproxy.com/${GITGPT}
fi
}

function NODEJS() {
SUCCESS "Node.js yarn detection and installation."
# 检查是否安装了Node.js
if ! command -v node &> /dev/null;then
    WARN "Node.js 未安装，正在进行安装..."
    # 安装 Node.js
    yum -y install libstdc++.so.glibc glibc lsof &>/dev/null
    curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash - &>/dev/null
	if [ $? -ne 0 ]; then
	    ERROR "NodeJS安装失败！"
	    exit 1
	fi
    while [ $attempts -lt $maxAttempts ]; do
        yum install -y nodejs &>/dev/null
        if [ $? -ne 0 ]; then
            ((attempts++))
            WARN "尝试安装NodeJS (Attempt: $attempts)"

            if [ $attempts -eq $maxAttempts ]; then
                ERROR "NodeJS安装失败，请尝试手动执行安装。"
                echo " 命令：yum install -y nodejs"
                exit 1
            fi
        else
            INFO "NodeJS installed."
            break
        fi
    done
else
    INFO "Node.js Installed..."
fi


if ! command -v yarn &> /dev/null;then
    WARN "yarn 未安装，正在进行安装..."
    # 安装 yarn
    npm install -g yarn &>/dev/null
	if [ $? -ne 0 ]; then
	    ERROR "NodeJS安装失败！"
	    exit 1
	fi
    while [ $attempts -lt $maxAttempts ]; do
        yum install -y yarn &>/dev/null
        if [ $? -ne 0 ]; then
            ((attempts++))
            WARN "尝试安装yarn (Attempt: $attempts)"

            if [ $attempts -eq $maxAttempts ]; then
                ERROR "yarn安装失败，请尝试手动执行安装。"
                echo " 命令：npm install -g yarn"
                exit 1
            fi
        else
            INFO "yarn installed."
            break
        fi
    done
else
    INFO "Node.js Installed..."
fi
}

function INFO_ENV() {
  # 交互输入ENV环境配置
  if [ -f .env ]; then
    last_input=$(cat .env)
  fi

  read -e -p "$(echo -e ${GREEN}"请输入 OPENAI_API_KEY（必填项）："${RESET})" OPENAI_API_KEY
  read -e -p "$(echo -e ${GREEN}"请输入访问密码 CODE，可选，可以使用逗号隔开多个密码："${RESET})" CODE
  read -e -p "$(echo -e ${GREEN}"请输入BASE_URL，默认为 https://api.openai.com："${RESET})" BASE_URL
  read -e -p "$(echo -e ${GREEN}"请输入OPENAI_ORG_ID，可选："${RESET})" OPENAI_ORG_ID
  read -e -p "$(echo -e ${GREEN}"请输入OPENAI 接口代理 URL，如果有配置代理(eg：http://clash:7890)，可选：："${RESET})" PROXY_URL
  read -e -p "$(echo -e ${GREEN}"如果你不想让用户自行填入 API Key，请将 HIDE_USER_API_KEY 环境变量设置为 1，可选："${RESET})" HIDE_USER_API_KEY
  read -e -p "$(echo -e ${GREEN}"如果你不想让用户使用 GPT-4，请将 DISABLE_GPT4 环境变量设置为 1，可选："${RESET})" DISABLE_GPT4
  read -e -p "$(echo -e ${GREEN}"如果你不想让用户查询余额，请将 HIDE_BALANCE_QUERY 环境变量设置为 1，可选："${RESET})" HIDE_BALANCE_QUERY

  if [ -z "$OPENAI_API_KEY" ]; then
    ${SETCOLOR_RED} && echo "警告：您没有输入 OPENAI_API_KEY，部署完成后将无法正常使用！！" && ${SETCOLOR_NORMAL}
  else
    ENV_LOCAL="$OPENAI_API_KEY $CODE $BASE_URL $OPENAI_ORG_ID $PROXY_URL $HIDE_USER_API_KEY $DISABLE_GPT4 $HIDE_BALANCE_QUERY"
    IFS=" " read -r API_KEY CODE BASE_URL OPENAI_ORG_ID PROXY_URL HIDE_USER_API_KEY DISABLE_GPT4 HIDE_BALANCE_QUERY <<< "$ENV_LOCAL"
echo "------------------------------------------------------------------------------------------------"
    ${SETCOLOR_SUCCESS} && echo "当前 OPENAI_API_KEY 为：${API_KEY}" && ${SETCOLOR_NORMAL}
    ${SETCOLOR_SUCCESS} && echo "当前页面访问密码为：${CODE}" && ${SETCOLOR_NORMAL}
    ${SETCOLOR_SUCCESS} && echo "当前 BASE_URL 为：${BASE_URL}" && ${SETCOLOR_NORMAL}
    ${SETCOLOR_SUCCESS} && echo "当前 OPENAI_ORG_ID 为：${OPENAI_ORG_ID}" && ${SETCOLOR_NORMAL}
    ${SETCOLOR_SUCCESS} && echo "当前代理地址为：${PROXY_URL}" && ${SETCOLOR_NORMAL}
    ${SETCOLOR_SUCCESS} && echo "当前 HIDE_USER_API_KEY 为：${HIDE_USER_API_KEY}" && ${SETCOLOR_NORMAL}
    ${SETCOLOR_SUCCESS} && echo "当前 DISABLE_GPT4 为：${DISABLE_GPT4}" && ${SETCOLOR_NORMAL}
    ${SETCOLOR_SUCCESS} && echo "当前 HIDE_BALANCE_QUERY 为：${HIDE_BALANCE_QUERY}" && ${SETCOLOR_NORMAL}
  fi

  echo "${ENV_LOCAL}" > .env
}


function CODE_BUILD() {
INFO "《构建中，请稍等...》"
# 安装依赖
yarn install 2>&1 >/dev/null | grep -E "error|fail|warning"
# 打包
OPENAI_API_KEY=${API_KEY} CODE={$CODE} PORT=${PROXY_URL} yarn build | grep -E "ERROR|ELIFECYCLE|WARN|*Done in*"
}


function BUILD() {
SUCCESS1 "开始进行构建.构建快慢取决于你的环境"
${SETCOLOR_NORMAL}
echo
SUCCESS "< 构建 >"
cd ${ORIGINAL}/${CHATDIR} && CODE_BUILD
SUCCESS "< END >"
echo
}


# 启动服务
function START_NEX() {
# 拷贝后端并启动
SUCCESS "<启动服务>"
# 添加开机自启
cat > /etc/systemd/system/chatgpt-next-web.service <<EOF
[Unit]
Description=ChatGPT NEX Web Service
After=network.target

[Service]
Type=simple
Environment="OPENAI_API_KEY=${API_KEY}"
Environment="CODE=${CODE}"
Environment="PROXY_URL=${PROXY_URL}"
Environment="BASE_URL=${BASE_URL}"
Environment="OPENAI_ORG_ID=${OPENAI_ORG_ID}"
Environment="HIDE_USER_API_KEY=${HIDE_USER_API_KEY}"
Environment="DISABLE_GPT4=${DISABLE_GPT4}"
Environment="HIDE_BALANCE_QUERY=${HIDE_BALANCE_QUERY}"
User=root
Group=root
WorkingDirectory=${ORIGINAL}/${CHATDIR} 
ExecStart=$(which yarn) start
Restart=always
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
TimeoutStopSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl restart chatgpt-next-web
systemctl enable chatgpt-next-web &>/dev/null

sleep 10
if pgrep -f "$(which yarn)" > /dev/null
then
    # 检测端口是否正在监听
    sleep 5
    if ss -tuln | grep ":3000" > /dev/null
    then
        SUCCESS1 "chatgpt-next-web后端服务已成功启动"
        echo
        INFO "首次安装,如需使用域名或80端口访问,请将如下配置加入到Nginx配置文件的server块中."
echo
cat << \EOF
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;        
        proxy_set_header X-Nginx-Proxy true;
        proxy_buffering off;
        proxy_redirect off;
    }
EOF
    else
        echo
        WARN "ERROR：后端服务端口 3000 未在监听"
        echo
        ERROR "----------------chatgpt-next-web后端服务启动失败，请查看错误日志 ↓↓↓----------------"
        journalctl -u chatgpt-next-web --no-pager
        ERROR "----------------chatgpt-next-web后端服务启动失败，请查看错误日志 ↑↑↑----------------"
        echo
        exit 1
    fi
else
    echo
    WARN "ERROR：后端服务进程未找到"
    echo
    ERROR "----------------chatgpt-next-web后端服务启动失败，请查看错误日志 ↓↓↓----------------"
    journalctl -u chatgpt-next-web --no-pager
    ERROR "----------------chatgpt-next-web后端服务启动失败，请查看错误日志 ↑↑↑----------------"
    echo
    exit 2
fi
SUCCESS "< END >"
}

function main() {
   CHECKFIRE
   NODEJS
   GITCLONE
   INFO_ENV
   BUILD
   START_NEX
}
main
