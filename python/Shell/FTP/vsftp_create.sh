#!/bin/bash

#Author:	zfy、hmy
#Date:		2017/09/28、2018-09-05
#filename	ftp_create

#description:	install vsftpd and configure


#step1==================================================
#yum 安装vsftpd
set -x

function CheckdirExit(){
	if [ ! -d $selectdir ];then
		mkdir -p $selectdir
	else
		echo "$selectdir was exited"
	fi
}

function CheckfileExit(){
        if [ ! -e $selectfile ];then
                touch $selectfile
        else
                echo "$selectfile was exited"
        fi
}
yum -y install vsftpd

#定义内外网配置目录与文件

neiwan_ftp_dir=/etc/vsftpd
waiwan_ftp_dir=/etc/vsftpd2

neiwan_ftp_conf=$neiwan_ftp_dir/vsftpd.conf

waiwan_ftp_conf=$waiwan_ftp_dir/vsftpd.conf

#判断外网配置文件目录是否存在
selectdir=$waiwan_ftp_dir
CheckdirExit


#=====================================================
cat > $neiwan_ftp_conf	<<EOF
anon_mkdir_write_enable=YES
anon_umask=002
anon_upload_enable=YES
anon_world_readable_only=NO
anonymous_enable=NO
ascii_download_enable=YES
ascii_upload_enable=YES
chroot_list_enable=YES
chroot_list_file=/etc/vsftpd/chroot_list
chroot_local_user=YES
connect_from_port_20=YES
dirmessage_enable=YES
guest_enable=YES
guest_username=ftp
listen_port=21
listen=YES
local_enable=YES
local_root=/home/data/ftp
local_umask=022
pam_service_name=vsftpd
vsftpd_log_file=/var/log/vsftpd.log
syslog_enable=YES
pasv_enable=YES
pasv_max_port=2238
pasv_min_port=2223
tcp_wrappers=YES
user_config_dir=/etc/vsftpd/vuser_conf
userlist_enable=YES
virtual_use_local_privs=YES
reverse_lookup_enable=NO
write_enable=YES
xferlog_enable=YES
xferlog_file=/var/log/xferlog
xferlog_std_format=YES
idle_session_timeout=6000

EOF

#==================================================
cat >$waiwan_ftp_conf <<EOF
anonymous_enable=NO
anon_world_readable_only=NO
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_umask=002
xferlog_file=/var/log/xferlog2
vsftpd_log_file=/var/log/vsftpd2.log
xferlog_std_format=YES
syslog_enable=YES
local_enable=YES
write_enable=YES
local_umask=022
local_root=/home/data/ftp
virtual_use_local_privs=YES
guest_enable=YES
guest_username=ftp
pam_service_name=vsftpd2
user_config_dir=/etc/vsftpd2/vuser_conf
ascii_upload_enable=YES
ascii_download_enable=YES
chroot_local_user=YES
chroot_list_enable=YES
chroot_list_file=/etc/vsftpd2/chroot_list
dirmessage_enable=YES
xferlog_enable=YES
dual_log_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=YES
listen_port=2121
pasv_enable=YES
pasv_min_port=2123
pasv_max_port=2138
reverse_lookup_enable=NO
userlist_enable=YES
tcp_wrappers=YES
idle_session_timeout=6000

EOF

#===============================================
#创建chroot_list目录
neiwan_ftp_cr=$neiwan_ftp_dir/chroot_list
waiwan_ftp_cr=$waiwan_ftp_dir/chroot_list
neiwan_ftp_vuser=$neiwan_ftp_dir/vuser_conf
waiwan_ftp_vuser=$waiwan_ftp_dir/vuser_conf

neiwan_ftp_logtxt=$neiwan_ftp_dir/vsftpd.login.txt
waiwan_ftp_logtxt=$waiwan_ftp_dir/vsftpd.login.txt

all_selectdir="$neiwan_ftp_cr $waiwan_ftp_cr $neiwan_ftp_vuser $waiwan_ftp_vuser"
for selectdir in $all_selectdir;
do
	CheckdirExit
done

all_selectfile="$neiwan_ftp_logtxt $waiwan_ftp_logtxt"

for selectfile in $all_selectfile;
do
	CheckfileExit
done


#========================================================
#定义FTP用户目录
ftp_user_dir=/home/data/ftp
selectdir=$ftp_user_dir
CheckdirExit



#==============pam模块=====================
#pam模块是为调用数据库对ftp用户登录进行验证

cat > /etc/pam.d/vsftpd <<EOF
auth required /lib64/security/pam_userdb.so db=/etc/vsftpd/vsftpd.login
account required /lib64/security/pam_userdb.so db=/etc/vsftpd/vsftpd.login
EOF

#========================
cat >/etc/pam.d/vsftpd2 <<EOF
auth required /lib64/security/pam_userdb.so db=/etc/vsftpd2/vsftpd.login
account required /lib64/security/pam_userdb.so db=/etc/vsftpd2/vsftpd.login
EOF

#==================================================================
#设置防火墙
iptables -F
iptables -X

iptables -N WBNET
/etc/init.d/iptables save
sed -i '/^COMMIT/d' /etc/sysconfig/iptables
sed -i '/Completed/d' /etc/sysconfig/iptables

cat >>/etc/sysconfig/iptables <<EOF
-A INPUT -j WBNET
-A FORWARD -j WBNET
-A WBNET -i lo -j ACCEPT
-A WBNET -p icmp -m icmp --icmp-type any -j ACCEPT
-A WBNET -m state --state RELATED,ESTABLISHED -j ACCEPT
-A WBNET -d 192.168.10.14/32 -p tcp -m state --state NEW -m tcp --dport 21 -j ACCEPT
-A WBNET -d 192.168.66.14/32 -p tcp -m state --state NEW -m tcp --dport 2121 -j ACCEPT
-A WBNET -d 192.168.10.14/32 -p tcp -m state --state NEW -m tcp --dport 25 -j ACCEPT
-A WBNET -d 192.168.10.14/32 -p tcp -m state --state NEW -m tcp --dport 110 -j ACCEPT
-A WBNET -d 192.168.10.14/32 -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT

-A WBNET -s 183.60.122.237 -p tcp -m tcp --dport 22 -j ACCEPT
-A WBNET -s 119.146.202.184 -p tcp -m tcp --dport 22 -j ACCEPT
-A WBNET -s 192.168.10.0/24 -p tcp -m tcp --dport 22 -j ACCEPT
-A WBNET -s 192.168.10.0/24 -p tcp -m tcp --dport 22 -j ACCEPT
-A WBNET -s 192.168.66.0/24 -p tcp -m tcp --dport 22 -j ACCEPT
-A WBNET -p tcp -m tcp --dport 22 -j DROP


-A WBNET -p tcp -m state --state NEW -m tcp --dport 8000 -j ACCEPT
-A WBNET -p tcp -m state --state NEW -m tcp --dport 8800 -j ACCEPT
-A WBNET -p tcp -m state --state NEW -m tcp --dport 873 -j ACCEPT
-A WBNET -p tcp -m state --state NEW -m tcp --dport 2123:2300 -j ACCEPT
-A WBNET -j REJECT --reject-with icmp-host-prohibited
COMMIT
# Completed on Fri Sep 29 10:06:16 2017

EOF

/etc/init.d/iptables restart

/usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf
/usr/sbin/vsftpd /etc/vsftpd2/vsftpd.conf

echo "/usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf" >>/etc/rc.d/rc.local
echo "/usr/sbin/vsftpd /etc/vsftpd2/vsftpd.conf" >>/etc/rc.d/rc.local


