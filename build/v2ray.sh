#!/bin/bash
cd "$(dirname "$BASH_SOURCE")"
source ./sysos.sh
GITURL="https://github.com/v2fly/v2ray-core.git"
V2RAYDIR="../puling_core/v2ray-core/"
BINDIR="../../fancyss_binary/"
PACKAGE_NAME='git go upx'
OS='linux'
ARM=7
ARCH='arm'


if [ ! -d $(dirname "$V2RAYDIR") ];then
    mkdir -p $(dirname "$V2RAYDIR")
fi

if [ ! -d $(dirname "$BINDIR") ];then
    mkdir -p $(dirname "$BINDIR")
fi


folder=$(realpath $V2RAYDIR)


#获取本地分支或获取sha1
# $1为项目路径如果为空就使用当前路径
git_branch () {
    if [ ! -d $folder ];then
        echo ""
    else
        localversion=$(git -C $folder rev-parse --abbrev-ref HEAD | grep -v HEAD || git -C $folder describe --exact-match HEAD 2> /dev/null ||   git -C $folder rev-parse HEAD)
        echo $localversion
    fi
}

#获取远程仓库tag版本号
git_tag_verion(){
    git_tag=$(git ls-remote --tags --sort="v:refname" $1 | tail -n1 | grep -o -E -e '[0-9a-f]{40}' )
    echo $git_tag
}

#验证系统环境
verif_info(){

    install_software $PACKAGE_NAME

    #验证项目文件是否存在
    remote_version=$1
    

    #判断项目文件是否为空，不为空验证本地版本与远程版本是否一样，不一样切换到指定版本。为空git最新代码回滚到指定版本
    if [ -d $folder ];then
        locat_version=$(git_branch $folder)
        if [ "$remote_version" != "$locat_version" ];then
            $(git -C $folder checkout $1 -q || git pull origin master $1 -q )
        fi
        return 0
    else
        echo -e "正在获取最新版本源码请等待。。。。。"
        echo -e "无科学速度严重可怕！"
        #本来版本和远程版本不同获取最新代码        
        $(git clone $GITURL $folder -q)
        $(git -C $folder checkout $1 -q || git pull origin master $1 -q )
        return 1
    fi
}
#v2ray编译
v2ray_buind(){

    echo "开启编译，为保证编译成功请科学上网模式编译不然请配置go环境代理相关配置"
    echo "下载源码相关依赖请稍后。。。"
    cd $folder && go mod download && go clean
    echo "开始编译，当前编译OS：$1 系统架构：$2 架构版本为：$3"
    CGO_ENABLED=0 GOOS=$1 GOARCH=$2 GOARM=$3 go build -a -o /tmp/v2ray_$2$3 -trimpath -ldflags "-s -w -buildid=" ./main
    CGO_ENABLED=0 GOOS=$1 GOARCH=$2 GOARM=$3 go build -a -o /tmp/v2ctl_$2$3 -trimpath -ldflags "-s -w -buildid=" -tags confonly ./infra/control/main
    
    binpath=$(realpath $BINDIR)
    #验证bin文件夹是否存在
    if [ ! -d $binpath ];then
        mkdir $binpath
    fi
    echo "压缩程序以达到最小"
    
    rm -rf $binpath/v2ray_$2$3
    rm -rf $binpath/v2ctl_$2$3
    upx --lzma --ultra-brute /tmp/v2ray_$2$3 -o $binpath\/v2ray_$2$3
    upx --lzma --ultra-brute /tmp/v2ctl_$2$3 -o $binpath\/v2ctl_$2$3
    cp -rf /tmp/v2ray_$2$3 $binpath\/v2ray_$2$3
    cp -rf /tmp/v2ctl_$2$3 $binpath\/v2ctl_$2$3

    v=$(git ls-remote --tags --sort="v:refname" $GITURL | tail -n1 | sed 's/.*\///; s/\^{}//')
    remov="sed -i '/v2ray_$2$3/d;/v2ctl_$2$3/'d $binpath/version"
    $(eval echo ${remov})
    echo "v2ray_$2$3 $(file_md5 $binpath\/v2ray_$2$3) $v" >> $binpath\/version
    echo "v2ctl_$2$3 $(file_md5 $binpath\/v2ctl_$2$3) $v" >> $binpath\/version
    #rm -rf /tmp/v2ray_$2$3
    #rm -rf /tmp/v2ctl_$2$3
    ln -snf $binpat\/v2ray_$2$3 v2ray
    ln -snf $binpat\/v2ctl_$2$3 v2ctl    
}

shell_parameters(){
    while [[ "$#" -gt '0' ]];do
        case "$1" in
            '--version')
                echo "v2ray 编译脚本0.1"
                break
                ;;
            '--help' | '-h')
                echo "脚本帮助！！！！！！！！！"
                echo "--os参数设置go编译目标系统"
                echo "--arm设置目标架构版本"
                echo "--arch设置目标架构"
                echo ""
                echo ""
                break
                ;;
            '--os')
                if [ ! -z "$2" ];then
                    echo "设置目标系统:$2"
                    OS=$2
                fi
                shift
                ;;
            '--arm')
                if [ ! -z "$2" ];then
                   echo "设置目标框架版本：$2"
                   ARM=$2
                else
                   ARM=''
                fi
                shift
                ;;
            '--arch')
                if [ ! -z "$2" ];then
                    echo "设置目标架构：$2"
                    ARCH=$2
                fi
                shift
                ;;
            *)
                echo "启用默认脚本参数"
                ;;
        esac
        shift
    done
}

#获取制定远程库tag代码
git_pull_tag(){
    echo -e "正在获取远程版本！！请保证网络畅通，你懂的无科学网络速度感人"
    version=$(git_tag_verion $GITURL)
    verif_info $version 
    branch=$(git_branch $V2RAYDIR)
    if [ -z "$version" ];then
        echo "无法获取版本号"
        exit 3
    else
        v2ray_buind $OS $ARCH $ARM
        #v2ray_buind 'linux' 'arm' 7
    fi
}

main(){
    shell_parameters "$@"
    git_pull_tag
    return 0
}

main "$@"
