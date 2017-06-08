#!/bin/bash
[php模块安装] php源码插件扩展
[mcrypt.so]  mcrypt 库的接口模块   
本扩展是 mcrypt 库提供了对多种块算法的支持， 包括：DES，TripleDES，Blowfish （默认）， 3-WAY，SAFER-SK64，SAFER-SK128，TWOFISH，TEA，RC2 以及 GOST，并且支持 CBC，OFB，CFB 和 ECB 密码模式。 甚至，它还支持诸如 RC6 和 IDEA 这两种“非免费”的算法。 默认情况下，CFB/OFB 是 8 比特的。    来源： http://php.net/manual/zh/intro.mcrypt.php

cd /root/deploy/php-5.6.21/ext/mcrypt/
yum install libmcrypt   libmcrypt-devel -y    ##依赖
/usr/local/php/bin/phpize  
ls  &&    ./configure  -h
./configure   --with-php-config=/usr/local/php/bin/php-config 
make  &&      make install
vim /usr/local/php/etc/php.ini 
/etc/init.d/php-fpm restart   && ps -ef|grep php

##############################################################################
[redis.so]     //redis模块安装 
redis-3.1.0.tgz  ;   download from   https://pecl.php.net/package/redis/redis-3.1.0.tgz   ;search from http://pecl.php.net/ 
tar   xf redis-3.1.0.tgz 
cd redis-3.1.0
/usr/local/php/bin/phpize  
./configure --help | grep config
./configure --with-php-config=/usr/local/php/bin/php-config 
make && make install
或者网络安装：(此法不一定可行 存在下载不了)
/usr/local/php/bin/pecl search redis
/usr/local/php/bin/pecl install redis
##############################################################################
[mysqlnd_ms.so]    //php5.5支持mysql插件 下载tar包
这个扩展, 主要实现了, 连接保持和切换, 负载均衡和读写分离等, 也就是说, 这个扩展会去分别PHP发给MySQL的query, 如果是”读”的query, 就会把query发送给从库(配置中指明), 并且支持负载均衡; 而如果是”写”的query, 就会把query发送给主库. 不过这个扩展需要搭配mysqlnd一起使用(从PHP5.4 beta1开始, 我们已经把mysqlnd作为mysql, mysqli, pdo的默认链接目标, 当然, 你也可以通过–with-mysql=***来制定你想要链接到libmysql).        来源： http://www.laruence.com/2011/10/05/2192.html
mv /home/caoqingshan/mysqlnd_ms-1.5.2.tgz ./
tar xf mysqlnd_ms-1.5.2.tgz 
cd mysqlnd_ms-1.5.2
/usr/local/php/bin/phpize 
./configure --help | grep config
./configure --with-php-config=/usr/local/php/bin/php-config 
make
make install
[root@127.0.0.1 mysqlnd_ms-1.5.2]# cat /usr/local/php/etc/php.ini |grep -v ';'|grep extension
extension=mysqlnd_ms.so
-------------------------------------------------------------------------------------------------------------------------
[mysqlnd]
mysqlnd.collect_statistics = On
mysqlnd.collect_memory_statistics = Off
mysqlnd_ms.enable=1
mysqlnd_ms.config_file=/usr/local/php/etc/mysqlnd_ms_plugin.in
-------------------------------------------------------------------------------------------------------------------------
[xiongzhen@127.0.0.1 ~]$ cat /usr/local/php/etc/mysqlnd_ms_plugin.ini
{
    "wps_pay": {
        "master": {
            "master_0": {
                "host": "172.16.8.53",
                "port": "3306"
            }
        },
        "slave": {
            "slave_0": {
                "host": "172.16.8.54",
                "port": "3306"
            }
        },
        "lazy_connections": 1,
        "trx_stickiness": "master",
        "server_charset": "utf8"
    }
}
##############################################################################
[openssl.so]  openssl模块 php源码插件扩展  加密、解密、认证
cd /data/tmp/php-5.5.30/ext/openssl/
/usr/local/php/bin/phpize 
cp   config0.m4 config.m4
/usr/local/php/bin/phpize 
  ./configure --with-openssl --with-php-config=/usr/local/php/bin/php-config 
make
make install
ls /usr/local/php-5.5.30/lib/php/extensions/no-debug-non-zts-20121212/
vim /usr/local/php/etc/php.ini 
extension=memcache.so
extension=redis.so
extension=mcrypt.so
extension=openssl.so
# /etc/init.d/php-fpm reload
##############################################################################
[opcache.so]  opcache模块 php源码插件扩展
--------------------------------------------------------------------------------
Zend OPcache 通过 opcode 缓存和优化提供更快的 PHP 执行过程。它将预编译的脚本文件存储在共享内存中供以后使用，从而避免了从磁盘读取代码并进行编译的时间消耗。同时，它还应用了一些代码优化模式，使得代码执行更快。
 /usr/local/php/etc/php.ini 配置Zend OPcache ，不要写到extension=opcache.so
[opcache]
zend_extension = opcache.so
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.enable_cli=1
##############################################################################
[pdo_mysql.so]     php源码插件扩展
PDO扩展为PHP访问数据库定义了一个轻量级的、一致性的接口，它提供了一个数据访问抽象层，这样，无论使用什么数据库，都可以通过一致的函数执行查询和获取数据

