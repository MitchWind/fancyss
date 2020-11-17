#!/bin/bash -
#===============================================================================
#
#          FILE: sysos.sh
#
#   DESCRIPTION: 执行系统相关检查
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: streetwind
#         EMAIL: mofeng64@gmail.com
#       CREATED: 2020年11月04日 11时38分41秒
#      REVISION:  ---
#===============================================================================

#验证当前命令是否存在
check_package(){
    local name=$@
    for i in $name
    do
        if [ ! "$(type -P $i)" ];then
            nopackage_name+="$i "
        fi
    done
    echo $nopackage_name
}

#安装软件包
install_software(){
    local package_name=$(check_package $@)

    if [[ "$(type -P apt)" ]]; then
      PACKAGE_MANAGEMENT_INSTALL='apt -y --no-install-recommends install'
      PACKAGE_MANAGEMENT_REMOVE='apt purge'     
    elif [[ "$(type -P dnf)" ]]; then
      PACKAGE_MANAGEMENT_INSTALL='dnf -y install'
      PACKAGE_MANAGEMENT_REMOVE='dnf remove'
    elif [[ "$(type -P yum)" ]]; then
      PACKAGE_MANAGEMENT_INSTALL='yum -y install'
      PACKAGE_MANAGEMENT_REMOVE='yum remove'
    elif [[ "$(type -P zypper)" ]]; then
      PACKAGE_MANAGEMENT_INSTALL='zypper install -y --no-recommends'
      PACKAGE_MANAGEMENT_REMOVE='zypper remove'
    elif [[ "$(type -P pacman)" ]]; then
      PACKAGE_MANAGEMENT_INSTALL='pacman -Syu --noconfirm'
      PACKAGE_MANAGEMENT_REMOVE='pacman -Rsn'
    else
      echo "无法找到系统安装命令"
    fi
    if [ -z "$package_name" ];then
        echo "当前软件环境正常无需安装"
    else
        echo “正在安装软件环境，当前安装软件有：$package_name”
        $('$PACKAGE_MANAGEMENT_INSTALL $package_name')
    fi
}
#文件md5 $1文件名
file_md5(){
    md5_latest=$(md5sum $1 | sed 's/ /\n/g' |sed -n 1p)
    echo $md5_latest 
}
