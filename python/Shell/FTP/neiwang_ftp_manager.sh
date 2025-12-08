#!/bin/bash
baseconf="/etc/vsftpd"
vuser_conf="/etc/vsftpd/vuser_conf"
usertxt="vsftpd.login.txt"
userdb="vsftpd.login.db"
ftp_home="/home/data/ftp"

ctrl_user(){
username=$1
if [[ "$username" == "" ]];then
        echo -e "\033[31m username can't null \033[0m"
fi
linenum=`grep -n "$username" $baseconf/$usertxt |head -n 1|awk -F ":" '{print $1}'`
if [[ "$linenum" == "" ]];then
        echo -e "\033[31m username not exist \033[0m"
        exit 1
fi
}

useradd(){
read -p "username(can't null):" username
read -p "password(can't null):" password
read -p "user home dir(default is /data/ftp/$username ):" home_dir
read -p "home dir  write privilege (YES or NO ,default NO):" privilege
if [[ "$username" == "" || "$password" == "" ]];then
	echo -e "\033[31m username(can't null),password(can't null) \033[0m"
	exit 1
fi

cat $baseconf/$usertxt|grep -w $username >/dev/null
if [ $? -eq 0 ];then
        echo -e "\033[31m user is  exist\033[0m"
        exit 1
fi

if [[ "$home_dir" == "" ]];then
	home_dir="$ftp_home/$username"
	mkdir $home_dir -p
	chown -R ftp:ftp $home_dir
else
	mkdir $home_dir -p
	chown -R ftp:ftp $home_dir
fi

if [[ -d $home_dir ]];then
        echo "check home dir ok"
else
        echo -e "\033[31m home dir no exist\033[0m"
        exit 1
fi


if [[ "$privilege" != "YES" ]];then
	privilege="NO"
fi

echo $username >> $baseconf/$usertxt
echo $password >> $baseconf/$usertxt
/usr/bin/db_load -T -t hash -f $baseconf/$usertxt $baseconf/$userdb

echo "write_enable=$privilege" >> $vuser_conf/$username
echo "local_umask=022" >> $vuser_conf/$username
echo "local_root=$home_dir" >> $vuser_conf/$username
}

userdel(){
read -p "delete username:" username
ctrl_user $username
sed -i "${linenum}d" $baseconf/$usertxt #delete user
sed -i "${linenum}d" $baseconf/$usertxt #delete password
rm -f $vuser_conf/$username
/usr/bin/db_load -T -t hash -f $baseconf/$usertxt $baseconf/$userdb
}

lookpw(){
read -p "username:" username
ctrl_user $username
linenum=$((${linenum}+1))
printf "password:"
sed -n "${linenum}p" $baseconf/$usertxt 
}

mdfpw(){
read -p "username:" username
read -p "new password:" password

if [[ "$password" == "" ]];then
	echo -e "\033[31m new password can't null \033[0m"
fi

ctrl_user $username
linenum=$((${linenum}+1))
#delete old password
sed -i "${linenum}d" $baseconf/$usertxt 
linenum=$((${linenum}-1))
sed -i "${linenum} a${password}" $baseconf/$usertxt #add new password
/usr/bin/db_load -T -t hash -f $baseconf/$usertxt $baseconf/$userdb
}

permit(){
read -p "username:" username
read -p "write primit (YES or NO,default NO)" quanxian
ctrl_user $username
if [[ "$quanxian" != "YES" &&  "$quanxian" != "NO" ]];then
	quanxian="NO"
fi
sed -i "/write_enable/cwrite_enable=$quanxian" $vuser_conf/$username
}

case $1 in 
    useradd)
	useradd
	;;
    userdel)
        userdel
        ;;
    lookpw)
        lookpw
        ;;
    mdfpw)
        mdfpw
        ;;
	permit)
	permit
	;;
    *)	
	echo "USAGE: sh $0 useradd|userdel|lookpw|mdfpw|permit"
	;;
esac
