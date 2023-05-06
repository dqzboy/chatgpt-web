#!/bin/bash

distro=$(awk -F= '/^NAME/{print $2}' /etc/os-release)

if [ "$distro" == "\"CentOS Linux\"" ]
then
    # Check if nginx is installed
    if ! command -v nginx &> /dev/null
    then
        echo "nginx not installed"
    else
        # Check if nginx is running
        if pgrep -x "nginx" > /dev/null
        then
            # Stop nginx service
            sudo systemctl stop nginx
            echo "nginx stopped"
        else
            echo "nginx not running"
        fi

        # Remove nginx
        sudo yum remove nginx -y &> /dev/null

        # Check if nginx is successfully uninstalled
        if [ $? -eq 0 ]
        then
            echo "nginx uninstalled"
        else
            echo "Failed to uninstall nginx"
        fi
    fi
    # Check if pnpm is installed
    if ! command -v pnpm &> /dev/null
    then
        echo "pnpm not installed"
    else
        # Remove pnpm
        sudo npm uninstall -g pnpm
        echo "pnpm uninstalled"
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
    # Check if nginx is installed
    if ! command -v nginx &> /dev/null
    then
        echo "nginx not installed"
    else
        # Check if nginx is running
        if pgrep -x "nginx" > /dev/null
        then
            # Stop nginx service
            sudo systemctl stop nginx
            echo "nginx stopped"
        else
            echo "nginx not running"
        fi

        # Remove nginx
        sudo apt-get remove nginx -y &> /dev/null

        # Check if nginx is successfully uninstalled
        if [ $? -eq 0 ]
        then
            echo "nginx uninstalled"
        else
            echo "Failed to uninstall nginx"
        fi
    fi

    # Check if pnpm is installed
    if ! command -v pnpm &> /dev/null
    then
        echo "pnpm not installed"
    else
        # Remove pnpm
        sudo npm uninstall -g pnpm
        echo "pnpm uninstalled"
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
