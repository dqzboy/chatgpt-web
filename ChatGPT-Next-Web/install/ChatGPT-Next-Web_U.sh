#!/usr/bin/env bash
#===============================================================================
#
#          FILE: ChatGPT-Next-Web_U.sh
# 
#         USAGE: ./ChatGPT-Next-Web_U.sh
#
#   DESCRIPTION: ChatGPT-Next-Web项目一键构建、部署、升级更新脚本
# 
#  ORGANIZATION: DingQz dqzboy.com 浅时光博客
#===============================================================================

SETCOLOR_SKYBLUE="echo -en \\E[1;36m"
SETCOLOR_SUCCESS="echo -en \\E[0;32m"
SETCOLOR_NORMAL="echo  -en \\E[0;39m"
SETCOLOR_RED="echo  -en \\E[0;31m"

# 定义项目仓库地址
GITGPT="https://github.com/Yidadaa/ChatGPT-Next-Web"
# 定义需要拷贝的文件目录
CHATDIR="ChatGPT-Next-Web"
ORIGINAL=${PWD}


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
echo -e "\033[32m机场推荐\033[0m(\033[34m按量不限时，解锁ChatGPT\033[0m)：\033[34;4mhttps://mojie.mx/#/register?code=CG6h8Irm\033[0m"

function SUCCESS_ON() {
${SETCOLOR_SUCCESS} && echo "-------------------------------------<提 示>-------------------------------------" && ${SETCOLOR_NORMAL}
}

function SUCCESS_END() {
${SETCOLOR_SUCCESS} && echo "-------------------------------------< END >-------------------------------------" && ${SETCOLOR_NORMAL}
echo
}
function PROMPT() {
${SETCOLOR_SKYBLUE} && echo "$1"  && ${SETCOLOR_NORMAL}
}

function CHECKFIRE() {
SUCCESS_ON
# Check if firewall is enabled
firewall_status=$(systemctl is-active firewalld)
if [[ $firewall_status == 'active' ]]; then
    # If firewall is enabled, disable it
    systemctl stop firewalld apparmor
    systemctl disable firewalld apparmor
    echo "Firewall has been disabled."
else
    echo "Firewall is already disabled."
fi
SUCCESS_END
}

function GITCLONE() {
${SETCOLOR_SUCCESS} && echo "-------------------------------<检测服务是否已运行>-------------------------------" && ${SETCOLOR_NORMAL}
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

${SETCOLOR_SUCCESS} && echo "-------------------------------------<项目克隆>-------------------------------------" && ${SETCOLOR_NORMAL}
${SETCOLOR_RED} && echo "                           注: 国内服务器请选择参数 2 "
SUCCESS_END
${SETCOLOR_NORMAL}

read -e -p "请选择你的服务器网络环境[国外1/国内2]： " NETWORK
if [ ${NETWORK} == 1 ];then
    cd ${ORIGINAL} && apt install git -y && git clone ${GITGPT}
elif [ ${NETWORK} == 2 ];then
    cd ${ORIGINAL} && apt install git -y && git clone https://ghproxy.com/${GITGPT}
fi
SUCCESS_END
}

function NODEJS() {
SUCCESS_ON
# 检查是否安装了Node.js
# 检查是否安装了Node.js
if ! command -v node &> /dev/null
then
    echo "Node.js 未安装，正在进行安装..."
    # 安装 Node.js
    curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash - &>/dev/null
    apt remove libnode72:amd64 libnode-dev -y &>/dev/null
    apt install -y nodejs &>/dev/null
else
    echo "Node.js 已安装..."
fi

# 检查是否安装了 yarn
if ! command -v yarn &> /dev/null
then
    echo "yarn 未安装，正在进行安装..."
    # 安装 yarn
    npm install -g yarn &>/dev/null
else
    echo "yarn 已安装..." 
fi
SUCCESS_END
}

function INFO() {
# 交互输入ENV环境配置
if [ -f .env ]; then
  last_input=$(cat .env)
  PROMPT "请在下面输入OPENAI_API_KEY/页面访问密码/代理地址(eg：http://127.0.0.1:7890),并用空格分隔;国外VPS代理可不写"
  read -e -p "请在此处填写,用空格分隔[上次记录：${last_input} 回车用上次记录]：" ENV_LOCAL
  if [ -z "${ENV_LOCAL}" ];then
      ENV_LOCAL="$last_input"
      API_KEY=$(echo "${ENV_LOCAL}" | cut -d' ' -f1)
      CODE=$(echo "${ENV_LOCAL}" | cut -d' ' -f2)
      PROXY_URL=$(echo "${ENV_LOCAL}" | cut -d' ' -f3)
      ${SETCOLOR_SUCCESS} && echo "当前OPENAI_API_KEY为：${API_KEY}" && ${SETCOLOR_NORMAL}
      ${SETCOLOR_SUCCESS} && echo "当前页面访问密码为：${CODE}" && ${SETCOLOR_NORMAL}
      ${SETCOLOR_SUCCESS} && echo "当前代理地址为：${PROXY_URL}" && ${SETCOLOR_NORMAL}
  else
      API_KEY=$(echo "${ENV_LOCAL}" | cut -d' ' -f1)
      CODE=$(echo "${ENV_LOCAL}" | cut -d' ' -f2)
      PROXY_URL=$(echo "${ENV_LOCAL}" | cut -d' ' -f3)
      ${SETCOLOR_SUCCESS} && echo "当前OPENAI_API_KEY为：${API_KEY}" && ${SETCOLOR_NORMAL}
      ${SETCOLOR_SUCCESS} && echo "当前页面访问密码为：${CODE}" && ${SETCOLOR_NORMAL}
      ${SETCOLOR_SUCCESS} && echo "当前代理地址为：${PROXY_URL}" && ${SETCOLOR_NORMAL}
  fi
else
  PROMPT "请在下面输入OPENAI_API_KEY/页面访问密码/代理地址(eg：http://127.0.0.1:7890),并用空格分隔;国外VPS代理可不写"
  read -e -p "请在此处填写,用空格分隔：" ENV_LOCAL
  if [ -z "${ENV_LOCAL}" ];then
      ${SETCOLOR_RED} && echo "您没输入OPENAI_API_KEY,部署完成后将无法正常使用！！" && ${SETCOLOR_NORMAL}
  else
      API_KEY=$(echo "${ENV_LOCAL}" | cut -d' ' -f1)
      CODE=$(echo "${ENV_LOCAL}" | cut -d' ' -f2)
      PROXY_URL=$(echo "${ENV_LOCAL}" | cut -d' ' -f3)
      ${SETCOLOR_SUCCESS} && echo "当前OPENAI_API_KEY为：${API_KEY}" && ${SETCOLOR_NORMAL}
      ${SETCOLOR_SUCCESS} && echo "当前页面访问密码为：${CODE}" && ${SETCOLOR_NORMAL}
      ${SETCOLOR_SUCCESS} && echo "当前代理地址为：${PROXY_URL}" && ${SETCOLOR_NORMAL}
  fi
fi
echo "${ENV_LOCAL}" > .env
}

function CODE_BUILD() {
${SETCOLOR_SKYBLUE} && echo "《构建中，请稍等...》" && ${SETCOLOR_NORMAL}
# 安装依赖
yarn install 2>&1 >/dev/null | grep -E "error|fail|warning"
# 打包
OPENAI_API_KEY=${API_KEY} CODE={$CODE} PORT=${PROXY_URL} yarn build | grep -E "ERROR|ELIFECYCLE|WARN|*Done in*"
}


function BUILD() {
SUCCESS_ON
echo "                           开始进行构建.构建快慢取决于你的环境"
SUCCESS_END
${SETCOLOR_NORMAL}
echo
${SETCOLOR_SUCCESS} && echo "-------------------------------------< 构建 >------------------------------------" && ${SETCOLOR_NORMAL}
cd ${ORIGINAL}/${CHATDIR} && CODE_BUILD
${SETCOLOR_SUCCESS} && echo "-------------------------------------< END >-------------------------------------" && ${SETCOLOR_NORMAL}
echo
}


# 启动服务
function START_NEX() {
# 拷贝后端并启动
echo
${SETCOLOR_SUCCESS} && echo "-----------------------------------<启动服务>-----------------------------------" && ${SETCOLOR_NORMAL}
# 添加开机自启
cat > /etc/systemd/system/chatgpt-next-web.service <<EOF
[Unit]
Description=ChatGPT NEX Web Service
After=network.target

[Service]
Type=simple
Environment="OPENAI_API_KEY=${API_KEY}"
Environment="CODE=${CODE}"
Environment="PORT=${PROXY_URL}"
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
        ${SETCOLOR_SUCCESS} && echo "chatgpt-next-web后端服务已成功启动" && ${SETCOLOR_NORMAL}
        PROMPT "首次安装,如需使用域名或80端口访问,请将如下配置加入到Nginx配置文件的server块中."
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
        echo "ERROR：后端服务端口 3000 未在监听"
        echo
        ${SETCOLOR_RED} && echo "----------------chatgpt-next-web后端服务启动失败，请查看错误日志 ↓↓↓----------------" && ${SETCOLOR_NORMAL}
        journalctl -u chatgpt-next-web --no-pager
        ${SETCOLOR_RED} && echo "----------------chatgpt-next-web后端服务启动失败，请查看错误日志 ↑↑↑----------------" && ${SETCOLOR_NORMAL}
        echo
        exit 1
    fi
else
    echo
    echo "ERROR：后端服务进程未找到"
    echo
    ${SETCOLOR_RED} && echo "----------------chatgpt-next-web后端服务启动失败，请查看错误日志 ↓↓↓----------------" && ${SETCOLOR_NORMAL}
    journalctl -u chatgpt-next-web --no-pager
    ${SETCOLOR_RED} && echo "----------------chatgpt-next-web后端服务启动失败，请查看错误日志 ↑↑↑----------------" && ${SETCOLOR_NORMAL}
    echo
    exit 2
fi
${SETCOLOR_SUCCESS} && echo "-------------------------------------< END >-------------------------------------" && ${SETCOLOR_NORMAL}

}

function main() {
   CHECKFIRE
   NODEJS
   GITCLONE
   INFO
   BUILD
   START_NEX
}
main
