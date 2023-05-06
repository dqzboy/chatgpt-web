#!/bin/bash

distro=$(awk -F= '/^NAME/{print $2}' /etc/os-release)

echo "-------------------------------<检测服务是否正在运行>-------------------------------"
# 检查服务进程是否正在运行
pid=$(lsof -t -i:3000)
if [ -z "$pid" ]; then
    echo "后端程序未运行"
else
    echo "后端程序正在运行,现在停止程序..."
    kill -9 $pid
fi

echo "-------------------------------<检测系统信息>-------------------------------"
if [ "$distro" == "\"CentOS Linux\"" ]
then
    # Check if yarn is installed
    if ! command -v yarn &> /dev/null
    then
        echo "yarn not installed"
    else
        # Remove yarn
        sudo npm uninstall -g yarn
        echo "yarn uninstalled"
    fi

    # Check if nodejs is installed
    if ! command -v node &> /dev/null
    then
        echo "nodejs not installed"
    else
        # Remove nodejs
        sudo yum remove nodejs -y &> /dev/null

        # Check if nodejs is successfully uninstalled
        if [ $? -eq 0 ]
        then
            echo "nodejs uninstalled"
        else
            echo "Failed to uninstall nodejs"
        fi
    fi

elif [ "$distro" == "\"Ubuntu\"" ]
then
    # Check if yarn is installed
    if ! command -v yarn &> /dev/null
    then
        echo "yarn not installed"
    else
        # Remove yarn
        sudo npm uninstall -g yarn
        echo "yarn uninstalled"
    fi
    # Check if nodejs is installed
    if ! command -v node &> /dev/null
    then
        echo "nodejs not installed"
    else
        # Remove nodejs
        sudo apt-get remove nodejs -y &> /dev/null

        # Check if nodejs is successfully uninstalled
        if [ $? -eq 0 ]
        then
            echo "nodejs uninstalled"
        else
            echo "Failed to uninstall nodejs"
        fi
    fi


else
    echo "Unsupported operating system"
fi
