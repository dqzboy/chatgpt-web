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

OSVER=$(lsb_release -is)



function CHECKMEM() {
INFO "Checking server memory resources. Please wait."
if ! command -v bc &> /dev/null; then
    while [ $attempts -lt $maxAttempts ]; do
        apt-get install -y bc lsof git &>/dev/null
        if [ $? -ne 0 ]; then
            ((attempts++))
            WARN "尝试安装内存计算工具 (Attempt: $attempts)"

            if [ $attempts -eq $maxAttempts ]; then
                ERROR "内存计算工具安装失败，请尝试手动执行安装。"
                echo "命令：apt-get install -y bc"
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
SUCCESS "Firewall  detection."
firewall_status=$(systemctl is-active firewalld)
if [[ $firewall_status == 'active' ]]; then
    # If firewall is enabled, disable it
    systemctl stop firewalld
    systemctl disable firewalld
    INFO "Firewall has been disabled."
else
    INFO "Firewall is already disabled."
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
  while [ $attempts -lt $maxAttempts ]; do
      apt-get install nginx -y &>/dev/null
      if [ $? -ne 0 ]; then
          ((attempts++))
          WARN "尝试安装Nginx (Attempt: $attempts)"

          if [ $attempts -eq $maxAttempts ]; then
              ERROR "Nginx安装失败，请尝试手动执行安装。"
              echo "命令：apt-get install nginx -y"
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
DONE
}

function NODEJS() {
SUCCESS "Node.js detection and installation."
# 检查是否安装了Node.js
if ! command -v node &> /dev/null;then
    ERROR "Node.js 未安装，正在进行安装..."
    # 安装 Node.js
    if [ "$OSVER" = "Ubuntu" ]; then
	curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash - &>/dev/null
        if [ $? -ne 0 ]; then
	    ERROR "NodeJS安装失败！"
	    exit 1
	fi
        while [ $attempts -lt $maxAttempts ]; do
            apt-get install -y nodejs &>/dev/null
            if [ $? -ne 0 ]; then
                ((attempts++))
                WARN "尝试安装NodeJS (Attempt: $attempts)"

                if [ $attempts -eq $maxAttempts ]; then
                    ERROR "NodeJS安装失败，请尝试手动执行安装。"
                    echo "命令：apt-get install -y nodejs"
                    exit 1
                fi
            else
                INFO "NodeJS installed."
                break
            fi
        done
    elif [ "$OSVER" = "Debian" ]; then
	curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash - &>/dev/null
	if [ $? -ne 0 ]; then
            ERROR "NodeJS安装失败！"
            exit 1
        fi
        while [ $attempts -lt $maxAttempts ]; do
            apt-get install -y nodejs &>/dev/null
            if [ $? -ne 0 ]; then
                ((attempts++))
                WARN "尝试安装NodeJS (Attempt: $attempts)"

                if [ $attempts -eq $maxAttempts ]; then
                    ERROR "NodeJS安装失败，请尝试手动执行安装。"
                    echo "命令：apt-get install -y nodejs"
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

# 检查是否安装了 yarn
if ! command -v yarn &> /dev/null
then
    WARN "yarn 未安装，正在进行安装..."
    # 安装 yarn
    while [ $attempts -lt $maxAttempts ]; do
        npm install -g yarn &>/dev/null
        if [ $? -ne 0 ]; then
            ((attempts++))
            WARN "尝试安装yarn (Attempt: $attempts)"

            if [ $attempts -eq $maxAttempts ]; then
                ERROR "yarn安装失败，请尝试手动执行安装。"
                echo "命令：npm install -g yarn"
                exit 1
            fi
        else
            INFO "yarn installed."
            break
        fi
    done
else
    INFO "yarn Installed..."
fi
DONE
}


function GITCLONE() {
SUCCESS "Verify the operational status of the service."
# 检查服务进程是否正在运行
pid=$(lsof -t -i:3000)
if [ -z "$pid" ]; then
    WARN "后端程序未运行"
    if [ -d "${ORIGINAL}/${CHATDIR}" ]; then
       rm -rf ${ORIGINAL}/${CHATDIR}
    fi
else
    WARN "后端程序正在运行,现在停止程序并更新..."
    kill -9 $pid
    if [ -d "${ORIGINAL}/${CHATDIR}" ]; then
       rm -rf ${ORIGINAL}/${CHATDIR}
    fi
fi

SUCCESS "Acquire the source code of the project."
WARN "注: 国内服务器请选择参数 2 使用Git代理服务"
${SETCOLOR_NORMAL}

read -e -p "$(echo -e ${GREEN}"请选择你的服务器网络环境[国外1/国内2]： "${RESET})" NETWORK
if [ ${NETWORK} == 1 ];then
    cd ${ORIGINAL} && git clone ${GITGPT}
elif [ ${NETWORK} == 2 ];then
    cd ${ORIGINAL} && git clone https://ghproxy.com/${GITGPT}
fi
}


function INFO_ENV() {
  # 交互输入ENV环境配置
  if [ -f .env ]; then
    last_input=$(cat .env)
  fi

  echo "------------------------------------------------------------------------------------------------"
  read -e -p "$(echo -e ${GREEN}"请输入 OPENAI_API_KEY（必填项）："${RESET})" OPENAI_API_KEY
  read -e -p "$(echo -e ${GREEN}"请输入访问密码,可选.可以使用逗号隔开多个密码："${RESET})" CODE
  read -e -p "$(echo -e ${GREEN}"请输入BASE_URL,默认为 https://api.openai.com："${RESET})" BASE_URL
  read -e -p "$(echo -e ${GREEN}"请输入OPENAI_ORG_ID，可选："${RESET})" OPENAI_ORG_ID
  read -e -p "$(echo -e ${GREEN}"请输入OPENAI 接口代理 URL，如果有配置代理(eg：http://clash:7890)，可选："${RESET})" PROXY_URL
  read -e -p "$(echo -e ${GREEN}"如果你不想让用户自行填入 API Key，请将 HIDE_USER_API_KEY 环境变量设置为 1，可选："${RESET})" HIDE_USER_API_KEY
  read -e -p "$(echo -e ${GREEN}"如果你不想让用户使用 GPT-4，请将 DISABLE_GPT4 环境变量设置为 1，可选："${RESET})" DISABLE_GPT4
  read -e -p "$(echo -e ${GREEN}"如果你不想让用户查询余额，请将 HIDE_BALANCE_QUERY 环境变量设置为 1，可选："${RESET})" HIDE_BALANCE_QUERY
  echo "------------------------------------------------------------------------------------------------"

  if [ -z "$OPENAI_API_KEY" ]; then
    ${SETCOLOR_RED} && echo "警告：您没有输入 OPENAI_API_KEY，部署完成后将无法正常使用！！" && ${SETCOLOR_NORMAL}
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
echo
SUCCESS1 "                 开始进行构建，构建快慢取决于你的环境"
echo
${SETCOLOR_NORMAL}
SUCCESS "< 构建 >"
cd ${ORIGINAL}/${CHATDIR} && CODE_BUILD
SUCCESS "< END >"
echo
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
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;        
        proxy_set_header X-Nginx-Proxy true;
        proxy_buffering off;
        proxy_redirect off;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF

# 检查 Nginx 配置
nginx -t &>/dev/null
# 检查返回值
if [ $? -eq 0 ]; then
    echo "Nginx 配置检查通过，开始重新加载..."
    nginx -s reload
else
    echo "Nginx 配置检查失败，请检查配置文件."
fi

elif [ "$NGCONF" = "n" ]; then
   WARN "You chose no."
else
   ERROR "Invalid parameter. Please enter 'y' or 'n'."
   exit 1
fi
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
Environment="OPENAI_API_KEY=${OPENAI_API_KEY}"
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
        NGINX_CONF
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
   CHECKMEM
   CHECKFIRE
   INSTALL_PACKAGE
   NODEJS
   INSTALL_NGINX
   GITCLONE
   INFO_ENV
   BUILD
   START_NEX
}
main
