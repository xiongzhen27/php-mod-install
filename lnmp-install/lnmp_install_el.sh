#!/bin/bash
#
# kso_lamp_install_el_v2.sh
#
# CopyRight@ KingSoft KSO Ltd. <caoqingshan@kingsoft.com>
# 
# last update: 2013-10-23 by CaoQingshan <caoqingshan@kingsoft.com>


# define colors
#
RES_COL=65
RES_COL_OB=1
MOVE_TO_COL="echo -en \\033[${RES_COL}G"
MOVE_TO_COL_SUB="echo -en \\033[${RES_COL_OB}G"
SETCOLOR_GREEN="echo -en \\033[1;32m"
SETCOLOR_RED="echo -en \\033[1;31m"
SETCOLOR_MAGENTA="echo -en \\033[1;35m"
SETCOLOR_YELLOW="echo -en \\033[1;33m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"


# os info
#
os_platform=$(uname -i)
os_version=$(cat /etc/system-release | awk '{print $(NF-1)}' | cut -d. -f 1)

# define var
#
date_now=$(date +%Y%m%d%H%M)
src_dir=/data/tmp
log_dir=/data/logs
default_prefix=/usr/local
install_log=${src_dir}/install_${date_now}.log


# system require packages
#
global_require_packages="wget gcc gcc-c++ make glibc glibc-devel autoconf automake bison"


# MySQL
#
mysql=mysql-5.6.30.tar.gz
mysql_url=http://cdn.mysql.com/Downloads/MySQL-5.6/${mysql}
mysql_requires="ncurses ncurses-devel cmake"
mysql_prefix=${default_prefix}/${mysql%.tar.gz}
mysql_data_dir=/data/db/mysql
mysql_log_dir=${log_dir}/mysql
mysql_compile_args="-DCMAKE_INSTALL_PREFIX=${mysql_prefix} \
                    -DMYSQL_DATADIR=${mysql_data_dir} \
                    -DDEFAULT_CHARSET=utf8 \
                    -DDEFAULT_COLLATION=utf8_general_ci \
                    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
                   "

# nginx source
#
nginx=nginx-1.8.0.tar.gz
nginx_url=http://nginx.org/download/${nginx}
nginx_requires="pcre pcre-devel gd gd-devel openssl openssl-devel"
nginx_prefix=${default_prefix}/${nginx%.tar.gz}
nginx_vhost_dir=${nginx_prefix}/conf/vhosts
nginx_run_dir=${nginx_prefix}/run
nginx_log_dir=${log_dir}/nginx
nginx_http_temp_dir=${nginx_prefix}/temp
nginx_compile_args="--prefix=${nginx_prefix} \
                    --http-log-path=${nginx_log_dir}/access.log \
                    --error-log-path=${nginx_log_dir}/error.log \
                    --lock-path=${nginx_run_dir}/nginx.lock \
                    --pid-path=${nginx_run_dir}/nginx.pid \
                    --http-client-body-temp-path=${nginx_http_temp_dir}/client_temp \
                    --http-proxy-temp-path=${nginx_http_temp_dir}/proxy_temp \
                    --http-fastcgi-temp-path=${nginx_http_temp_dir}/fastcgi_temp \
                    --http-uwsgi-temp-path=${nginx_http_temp_dir}/uwsgi_temp \
                    --http-scgi-temp-path=${nginx_http_temp_dir}/scgi_temp \
                    --with-http_realip_module \
                    --with-http_ssl_module \
                    --with-http_addition_module \
                    --with-http_stub_status_module \
                    --with-http_sub_module \
                    --with-http_gzip_static_module \
                    --with-http_image_filter_module \
                    --without-mail_pop3_module \
                    --without-mail_imap_module \
                    --without-mail_smtp_module \
                    --with-pcre \
                    "

# openresty source
#
openresty=openresty-1.7.2.1.tar.gz
openresty_url=http://openresty.org/download/ngx_${openresty}
openresty_requires="pcre-devel zlib-devel openssl-devel"
openresty_prefix=${default_prefix}/${openresty%.tar.gz}
openresty_vhost_dir=${openresty_prefix}/nginx/conf/vhosts
openresty_run_dir=${openresty_prefix}/nginx/run
openresty_log_dir=${log_dir}/nginx
openresty_http_temp_dir=${openresty_prefix}/nginx/temp
openresty_compile_args="--prefix=${openresty_prefix} \
                        --http-log-path=${openresty_log_dir}/access.log \
                        --error-log-path=${openresty_log_dir}/error.log \
                        --lock-path=${openresty_run_dir}/nginx.lock \
                        --pid-path=${openresty_run_dir}/nginx.pid \
                        --http-client-body-temp-path=${openresty_http_temp_dir}/client_temp \
                        --http-proxy-temp-path=${openresty_http_temp_dir}/proxy_temp \
                        --http-fastcgi-temp-path=${openresty_http_temp_dir}/fastcgi_temp \
                        --http-uwsgi-temp-path=${openresty_http_temp_dir}/uwsgi_temp \
                        --http-scgi-temp-path=${openresty_http_temp_dir}/scgi_temp \
                        --with-http_stub_status_module \
                        --with-http_realip_module \
                        --with-http_secure_link_module \
                        --with-http_ssl_module \
                        --with-luajit \
                        --with-lua51=lua-5.1.5 \
                        --without-mail_pop3_module \
                        --without-mail_imap_module \
                        --without-mail_smtp_module \
                        --without-poll_module \
                        --without-select_module \
                        --without-http_ssi_module \
                        --without-http_autoindex_module \
                        --without-http_encrypted_session_module \
                        --with-pcre \
                        "

# php source
#
php=php-5.6.9.tar.gz
php_url=http://cn2.php.net/distributions/${php}
php_requires_base="gd gd-devel \
                   libjpeg libjpeg-devel \
                   libxml2 libxml2-devel \
                   libpng libpng-devel \
                   "
if [ ${os_version} == "AMI" ]; then
    php_requires_opt="libcurl libcurl-devel"
elif [ ${os_version} -le 5 ]; then
    php_requires_opt="curl curl-devel"
elif [ ${os_version} -ge 6 ]; then
    php_requires_opt="libcurl libcurl-devel"
fi
php_requires="${php_requires_base} ${php_requires_opt}"

php_prefix=${default_prefix}/${php%.tar.gz}

# compile args for mini install
php_compile_args_mini="--prefix=${php_prefix} \
                       --with-config-file-path=${php_prefix}/etc
                       --disable-ipv6 \
                       --with-curl \
                       --with-mysql=mysqlnd \
                       --with-mysqli=mysqlnd \
                       --with-libxml-dir \
                       --enable-mbstring \
                       --enable-sockets \
                       --enable-fpm \
                       --enable-opcache \
                       "

# compile args for normal
php_compile_args_normal="--prefix=${php_prefix} \
                         --with-config-file-path=${php_prefix}/etc
                         --disable-ipv6 \
                         --with-gd \
                         --enable-gd-native-ttf \
                         --with-curl \
                         --enable-fpm \
                         --with-mysql=mysqlnd \
                         --with-mysqli=mysqlnd \
                         --with-jpeg-dir \
                         --with-png-dir \
                         --with-iconv-dir \
                         --with-libxml-dir \
                         --enable-mbstring \
                         --enable-sockets \
                         --with-freetype-dir \
                         --enable-opcache \
                         "

# print main menu
#
show_menu() {
    echo "+----------------------------------------------------------------------+"
    echo "|CentOS 5/6 Package Install Script                                     |"
    echo "|CopyRight @KingSoft Ltd. caoqingshan@kingsoft.com                     |"
    echo "|                                                                      |"
    echo "|1. Install Nginx 1.8.0                                                |"
    echo "|2. Install OpenResty 1.7.2.1                                          |"
    echo "|3. Install PHP 5.6.09 (FPM with mini compile)                         |"
    echo "|4. Install PHP 5.6.09 (FPM with normal compile)                       |"
    echo "|5. Install MySQL 5.6.30                                               |"
    echo "|q. Quit                                                               |"
    echo "+----------------------------------------------------------------------+"
    ${SETCOLOR_MAGENTA}
    echo
    read -p "Please chose [1-4, q to quit]: " CN
    echo
    ${SETCOLOR_NORMAL}
    case $CN in
        1)
            do_install nginx
        ;;
        2)
            do_install openresty
        ;;
        3)
            do_install php mini
        ;;
        4)
            do_install php normal
        ;;
        5)
            do_install mysql
        ;;
        q)
            exit 0
        ;;
    esac
}

# print install package begin
#
echo_banner() {
    echo -n ">>> Installing " | tee -a ${install_log}
    ${SETCOLOR_GREEN}
    echo " $1" | tee -a ${install_log}
    ${SETCOLOR_NORMAL}
}

# print sub banner
#
echo_banner_sub() {
    $MOVE_TO_COL_SUB
    ${SETCOLOR_GREEN}
    echo -n " * " | tee -a ${install_log}
    ${SETCOLOR_NORMAL}
    echo -n "$1" | tee -a ${install_log}
    return 0
}

# print install package success
#
echo_install_success() {
    echo -n ">>> Installing " | tee -a ${install_log}
    ${SETCOLOR_GREEN}
    echo -n " SUCCESS" | tee -a ${install_log}
    ${SETCOLOR_NORMAL}
    echo -n " to" | tee -a ${install_log}
    ${SETCOLOR_GREEN}
    echo " $1" | tee -a ${install_log}
    ${SETCOLOR_NORMAL}
}

# print install package failure
#
echo_install_failure() {
    echo -n ">>> Installing " | tee -a ${install_log}
    ${SETCOLOR_RED}
    echo " FAILED" | tee -a ${install_log}
    echo -ne "\n"
    ${SETCOLOR_YELLOW}
    echo "Why? See ${install_log}"
    ${SETCOLOR_NORMAL}
    echo -ne "\n"
    exit 1
}

# print success 
#
echo_success() {
    $MOVE_TO_COL 
    echo -n "["
    ${SETCOLOR_GREEN}
    echo -n "  OK  "
    ${SETCOLOR_NORMAL}
    echo -n "]"
    echo -ne "\n"
    return 0
}

# print failure
#
echo_failure() {
    $MOVE_TO_COL
    echo -n "["
    ${SETCOLOR_RED}
    echo -n "FAILED"
    ${SETCOLOR_NORMAL}
    echo -n "]"
    echo -ne "\n"
    return 1
}

# print pass
#
echo_pass() {
    $MOVE_TO_COL
    echo -n "["
    ${SETCOLOR_YELLOW}
    echo -n " PASS "
    ${SETCOLOR_NORMAL}
    echo -n "]"
    echo -ne "\n"
    return 0
}


# download source from internet
#
get_source() {
    local not_echo_success=0
    if [ "$1" = "not_echo_banner" ]; then
        not_echo_success=1
        shift
    else
        echo_banner_sub "download source"
    fi
    while [ $# -gt 0 ]; do
        local pkg_name=${!1}
        local pkg_url=${1}_url
        [ ! -f ${src_dir}/${pkg_name} -o ! -s ${src_dir}/${pkg_name} ] && wget ${!pkg_url} -O ${src_dir}/${pkg_name} >>${install_log} 2>&1
        if [ ! -s ${src_dir}/${pkg_name} ]; then
            echo_failure
            echo_install_failure
        fi
        shift
    done
    [ ${not_echo_success} -ne 1 ] && echo_success
}

# install requires packages usage: install_requires pk1 pk2 ...
#
install_requires() {
    local req_pkg="${global_require_packages} $*"
    local req_pkg_ins=""
    echo_banner_sub "install requires"
    for pkg in ${req_pkg}; do
        rpm -q ${pkg} >>${install_log} 2>&1
        if [ $? -eq 1 ]; then
            req_pkg_ins="${pkg} ${req_pkg_ins}"
        fi
    done
    if [ "x${req_pkg_ins}" != "x" ]; then
        yum install -y ${req_pkg_ins} >>${install_log} 2>&1
        if [ $? -eq 0 ]; then
            echo_success
        else
            echo_failure
            echo_install_failure
        fi
    else
        echo_pass
    fi
}

# check if package has been insalled 
# 0: not installed
# 1: installed
#
is_installed() {
    find_dir="${default_prefix}/$1"
    inst_dir=""
    for dir in ${find_dir}; do
        [ -d ${dir} ] && inst_dir="${inst_dir} ${dir}"
    done
    if [ -z "${inst_dir}" ]; then
        return 0
    else
        echo_banner_sub "$1 has been installed at:" && ${SETCOLOR_GREEN} && echo -e "\t${inst_dir}" && ${SETCOLOR_NORMAL} | tee -a ${install_log} && return 1
    fi
}

# install mysql 5.6.x
#
install_mysql() {

    echo_banner "${mysql%.tar.gz}"

    install_requires ${mysql_requires}

    get_source mysql

    # create mysql user if it isn't exist
    id mysql >>${install_log} 2>&1
    [ $? -ne 0 ] && useradd -c "MySQL" -r -d ${mysql_data_dir} -M -s /sbin/nologin mysql >>${install_log} 2>&1

    tar xf ${src_dir}/${mysql} -C ${src_dir}
    cd ${src_dir}/${mysql%.tar.gz}

    echo_banner_sub "cmake"
    cmake ${mysql_compile_args} . >>${install_log} 2>&1
    if [ $? -eq 0 ]; then echo_success; else echo_failure; echo_install_failure; fi

    echo_banner_sub "make"
    make >>${install_log} 2>&1
    if [ $? -eq 0 ]; then echo_success; else echo_failure; echo_install_failure; fi

    echo_banner_sub "make install"
    make install >>${install_log} 2>&1
    if [ $? -eq 0 ]; then echo_success; else echo_failure; echo_install_failure; fi

    echo_banner_sub "install database"
    # rename /etc/my.cnf if it exist!
    if [ -f /etc/my.cnf -o -L /etc/my.cnf ]; then 
        mv /etc/my.cnf /etc/my.cnf.${date_now} >>${install_log} 2>&1
    fi

    # install mysql database default tables
    [ -d ${mysql_data_dir%/*} ] || mkdir -p ${mysql_data_dir%/*} >>${install_log} 2>&1
    cd ${mysql_prefix} >>${install_log} 2>&1
    chown -R mysql:mysql . >>${install_log} 2>&1
    scripts/mysql_install_db --user=mysql --basedir=${mysql_prefix} --datadir=${mysql_data_dir} >>${install_log} 2>&1
    if [ $? -eq 0 -a -d ${mysql_data_dir}/mysql ]; then echo_success; else echo_failure; echo_install_failure; fi

    echo_banner_sub "setup"
    chown -R root . >>${install_log} 2>&1
    chown -R mysql data >>${install_log} 2>&1
    mkdir etc >>${install_log} 2>&1
    cp ${mysql_prefix}/support-files/my-default.cnf ${mysql_prefix}/etc/my.cnf >>${install_log} 2>&1
    if [ $? -ne 0 ]; then echo_failure; echo_install_failure; fi

    # create log dir
    if [ ! -d ${mysql_log_dir} ]; then
        mkdir -p ${mysql_log_dir} >>${install_log} 2>&1
        chown mysql:mysql ${mysql_log_dir} >>${install_log} 2>&1
    fi

    # make link /etc/my.cnf to mysql config file
    [ -r ${mysql_prefix}/etc/my.cnf ] && ln -s ${mysql_prefix}/etc/my.cnf /etc/my.cnf >>${install_log} 2>&1

    # add mysql lib to ldconfig database
    if [ -e /etc/ld.so.conf.d/${mysql%.tar.gz}.el${os_version}.${os_platform}.conf ]; then
        mv /etc/ld.so.conf.d/${mysql%.tar.gz}.el${os_version}.${os_platform}.conf /etc/ld.so.conf.d/${mysql%.tar.gz}.el${os_version}.${os_platform}.conf.${date_now} >>${install_log} 2>&1
    fi
    echo "${mysql_prefix}/lib" > /etc/ld.so.conf.d/${mysql%.tar.gz}.el${os_version}.${os_platform}.conf
    ldconfig >>${install_log} 2>&1

    # cp mysql init script to system init.d directory, backup orig file if it exsit
    if [ -x /etc/init.d/mysqld ]; then
        chkconfig mysqld off >>${install_log} 2>&1
        mv /etc/init.d/mysqld /etc/init.d/mysqld.${date_now} >>${install_log} 2>&1
    fi
    cp ${mysql_prefix}/support-files/mysql.server /etc/init.d/mysqld >>${install_log} 2>&1
    chkconfig --add mysqld && chkconfig mysqld on >>${install_log} 2>&1   
    if [ -x /etc/init.d/mysqld -a -L /etc/my.cnf -a -f /etc/ld.so.conf.d/${mysql%.tar.gz}.el${os_version}.${os_platform}.conf ]; then echo_success; else echo_failure; echo_install_failure; fi

    echo_install_success ${mysql_prefix}
}

# install nginx
#
install_nginx() {

    echo_banner "${nginx%.tar.gz}"

    install_requires ${nginx_requires}

    get_source nginx

    # create nginx user if it isn't exist
    id kmmaster >>${install_log} 2>&1
    [ $? -ne 0 ] && groupadd -g 900 kmmaster && useradd -c "nginx user" -r -d /dev/null -M -s /sbin/nologin -u 900 -g 900 kmmaster >>${install_log} 2>&1

    tar xf ${src_dir}/${nginx} -C ${src_dir} >>${install_log} 2>&1

    cd ${src_dir}/${nginx%.tar.gz} >>${install_log} 2>&1    
    echo_banner_sub "configure"
    ./configure ${nginx_compile_args} >>${install_log} 2>&1
    if [ $? -eq 0 ]; then echo_success; else echo_failure ; echo_install_failure; fi

    echo_banner_sub "make"
    make >>${install_log} 2>&1
    if [ $? -eq 0 ]; then echo_success; else echo_failure ; echo_install_failure; fi

    echo_banner_sub "make install"
    make install >>${install_log} 2>&1
    if [ $? -eq 0 ]; then echo_success; else echo_failure ; echo_install_failure; fi

    # set up nginx
    #
    echo_banner_sub "setting up"
    [ -d ${nginx_http_temp_dir} ] || mkdir -p ${nginx_http_temp_dir}  >>${install_log} 2>&1
    [ -d ${nginx_run_dir} ] || mkdir -p ${nginx_run_dir}  >>${install_log} 2>&1
    [ -d ${nginx_log_dir} ] || mkdir -p ${nginx_log_dir}  >>${install_log} 2>&1
    [ -d ${nginx_vhost_dir} ] || mkdir -p ${nginx_vhost_dir}  >>${install_log} 2>&1
    if [ $? -eq 0 ]; then echo_success; else echo_failure ; echo_install_failure; fi

    echo_install_success ${nginx_prefix}
}

# install openresty
#
install_openresty() {

    echo_banner "${openresty%.tar.gz}"

    install_requires ${openresty_requires}

    get_source openresty

    # create openresty user if it isn't exist
    id kmmaster >>${install_log} 2>&1
    [ $? -ne 0 ] && groupadd -g 900 kmmaster && useradd -c "nginx user" -r -d /dev/null -M -s /sbin/nologin -u 900 -g 900 kmmaster >>${install_log} 2>&1

    tar xf ${src_dir}/${openresty} -C ${src_dir} >>${install_log} 2>&1

    cd ${src_dir}/ngx_${openresty%.tar.gz} >>${install_log} 2>&1    
    echo_banner_sub "configure"
    ./configure ${openresty_compile_args} >>${install_log} 2>&1
    if [ $? -eq 0 ]; then echo_success; else echo_failure ; echo_install_failure; fi

    echo_banner_sub "make"
    gmake >>${install_log} 2>&1
    if [ $? -eq 0 ]; then echo_success; else echo_failure ; echo_install_failure; fi

    echo_banner_sub "make install"
    gmake install >>${install_log} 2>&1
    if [ $? -eq 0 ]; then echo_success; else echo_failure ; echo_install_failure; fi

    # set up openresty
    #
    echo_banner_sub "setting up"
    [ -d ${openresty_http_temp_dir} ] || mkdir -p ${openresty_http_temp_dir}  >>${install_log} 2>&1
    [ -d ${openresty_run_dir} ] || mkdir -p ${openresty_run_dir}  >>${install_log} 2>&1
    [ -d ${openresty_log_dir} ] || mkdir -p ${openresty_log_dir}  >>${install_log} 2>&1
    [ -d ${openresty_vhost_dir} ] || mkdir -p ${openresty_vhost_dir}  >>${install_log} 2>&1
    if [ $? -eq 0 ]; then echo_success; else echo_failure ; echo_install_failure; fi

    echo_install_success ${openresty_prefix}
}


# install php 
#
install_php() {

    echo_banner "${php%.tar.gz}"

    install_requires ${php_requires}

    get_source php

    # create nginx user if it isn't exist
    id kmmaster >>${install_log} 2>&1
    [ $? -ne 0 ] && groupadd -g 900 kmmaster && useradd -c "nginx user" -r -d /dev/null -M -s /sbin/nologin -u 900 -g 900 kmmaster >>${install_log} 2>&1

    tar xf ${src_dir}/${php} -C ${src_dir} >>${install_log} 2>&1
    cd ${src_dir}/${php%.tar.gz} >>${install_log} 2>&1

    echo_banner_sub "configure"
    [ "$1" == "mini" ] && php_compile_args=${php_compile_args_mini}
    [ "$1" == "normal" ] && php_compile_args=${php_compile_args_normal}
    ./configure ${php_compile_args} >>${install_log} 2>&1
    if [ $? -eq 0 ]; then echo_success; else echo_failure; echo_install_failure; fi

    echo_banner_sub "make"
    make >>${install_log} 2>&1
    if [ $? -eq 0 ]; then echo_success; else echo_failure; echo_install_failure; fi

    echo_banner_sub "make install"
    make install >>${install_log} 2>&1
    if [ $? -eq 0 ]; then echo_success; else echo_failure; echo_install_failure; fi

    echo_banner_sub "config PHP"
    cp php.ini-production ${php_prefix}/etc/php.ini >>${install_log} 2>&1
    if [ -f /etc/init.d/php-fpm ]; then
        cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm.${date_now}
        chmod +x /etc/init.d/php-fpm.${date_now}
    else
        cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
        chmod +x /etc/init.d/php-fpm
        chkconfig --add php-fpm
    fi
    if [ $? -eq 0 ]; then echo_success; else echo_failure; echo_install_failure; fi
        
    install_php_extension

    echo_install_success ${php_prefix}
}

# install php extension
#
install_php_extension() {

    # install memcache extension
    #
    echo_banner_sub "PHP memcache extension"
    printf "\n" | ${php_prefix}/bin/pecl install memcache >>${install_log} 2>&1 && sed -i '/; default extension directory./a\\extension=memcache.so' ${php_prefix}/etc/php.ini
    if [ $? -eq 0 ]; then echo_success; else echo_failure ; echo_install_failure; fi

    # install pac extension
    #
    #echo_banner_sub "PHP apc extension"
    #printf "\n" | ${php_prefix}/bin/pecl install apc >>${install_log} 2>&1 && sed -i '/; default extension directory./a\\extension=apc.so' ${php_prefix}/etc/php.ini
    #if [ $? -eq 0 ]; then echo_success; else echo_failure ; echo_install_failure; fi
}

# install function, args is package name
#
do_install() {
    local install_prefix=${1}_prefix
    if [ -n "$2" ]; then
        compile_args=${1}_compile_args_${2}
    else
        compile_args=${1}_compile_args
    fi
    while :
    do
        echo "+----------------------------------------------------------------------+"
        echo "|x|X: show compile args info                                           |"
        echo "|i|I: begin install                                                    |"
        echo "|r|R: return main menu                                                 |"
        echo "+----------------------------------------------------------------------+"
        ${SETCOLOR_MAGENTA}
        echo
        read -p "Please input your choise: " CN
        echo
        ${SETCOLOR_NORMAL}
        case "${CN}" in
            x|X)
                echo "$1 compile args is:"
                echo
                ${SETCOLOR_GREEN}
                for args in ${!compile_args}; do
                    echo ${args}
                done
                ${SETCOLOR_NORMAL}
                echo
            ;;
            i|I)
                is_installed ${!install_prefix#${default_prefix}/}
                if [ $? -ne 1 ]; then
                    install_${1} $2
                fi
                echo
            ;;
            r|R)
                return 0
            ;;
        esac
    done    
}

# start main
#

[ -d ${src_dir} ] || mkdir -p ${src_dir}
[ -d ${log_dir} ] || mkdir -p ${log_dir}
[ -d ${default_prefix} ] || mkdir -p ${default_prefix}
[ -f ${install_log} ] || touch ${install_log}

while :
do
    show_menu
done

