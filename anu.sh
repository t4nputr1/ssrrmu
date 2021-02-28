#!/bin/bash

MYIP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0' | head -n1`;
#MYIP=$(wget -qO- ipv4.icanhazip.com)
clear
# go to root
cd

# get the VPS IP
#ip=`ifconfig venet0:0 | grep 'inet addr' | awk {'print $2'} | sed s/.*://`
ip=$(ifconfig | grep 'inet addr:' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d: -f2 | awk '{ print $1}' | head -1)
if [ "$ip" = "" ]; then
	ip=$(wget -qO- ipv4.icanhazip.com)
fi
	

clear
echo "Please enter the username you want to set (do not repeat, does not support Chinese, will be reported incorrect!)"
read -e -p "(Default: ):" ssr_user
read -p "Berapa hari account [$ssr_user] aktif: " AKTIF

today="$(date +"%Y-%m-%d")"
expire=$(date -d "$AKTIF days" +"%Y-%m-%d")

lastport=$(cat /usr/local/shadowsocksr/mudb.json | grep '"port": ' | tail -n1 | awk '{print $2}' | cut -d "," -f 1 | cut -d ":" -f 1 )
ssr_port=$((lastport+1))

ssr_password="$ssr_user"

ssr_method="aes-256-cfb"

ssr_protocol="origin"

ssr_obfs="tls1.2_ticket_auth_compatible"

ssr_protocol_param="2"

ssr_speed_limit_per_con=0

ssr_speed_limit_per_user=0

ssr_transfer="838868"

ssr_forbid=""

ssr_enable_yn ="y"

SSRprotocol=$(echo $ssr_protocol | sed 's/_compatible//g')
SSRobfs=$(echo $ssr_obfs | sed 's/_compatible//g')
SSRPWDbase64=$(urlsafe_base64 "$ssr_user")
SSRbase64=$(urlsafe_base64 "$ip:$port:$SSRprotocol:$method:$SSRobfs:$SSRPWDbase64")
SSRurl="ssr://$SSRbase64"
ssr_link=" SSR Link : $SSRurl "

clear 
echo " Deatil Account ShadowsocksR"
echo -e "==================================================="
echo -e " User [$ssr_user] configuration info："
echo -e " IP : $ip"
echo -e " Port : $port"
echo -e " Password : $ssr_user"
echo -e " Encryption : $method"
echo -e " Protocol : $protocol"
echo -e " obfs : $ssr_obfs"
echo -e " Masa Aktif : $(date -d "$AKTIF days" +"%d-%m-%Y")"
echo -e " Device limit : $protocol_param"
echo -e " Single thread speed limit : $speed_limit_per_con KB/S"
echo -e " Total user speed limit : $speed_limit_per_user KB/S$"
echo -e " Forbidden port : Allow all"
echo -e "${ssr_link}"
echo "==================================================="
