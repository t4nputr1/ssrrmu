#!/bin/bash

Get_IP(){
	ip=$(wget -qO- -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ip}" ]]; then
		ip=$(wget -qO- -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ip}" ]]; then
			ip=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
			if [[ -z "${ip}" ]]; then
				ip="VPS_IP"
			fi
		fi
	fi
}
ip=$(cat ${config_user_api_file}|grep "SERVER_PUB_ADDR = "|awk -F "[']" '{print $2}')
	[[ -z "${ip}" ]] && Get_IP
	
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[information]${Font_color_suffix}"
Error="${Red_font_prefix}[error]${Font_color_suffix}"
Tip="${Green_font_prefix}[note]${Font_color_suffix}"
Separator_1="——————————————————————————————"

clear
echo "Please enter the username you want to set (do not repeat, does not support Chinese, will be reported incorrect!)"
read -e -p "(Default: ):" ssr_user
echo && echo ${Separator_1} && echo -e "	username : ${Green_font_prefix}${ssr_user}${Font_color_suffix}" && echo ${Separator_1} && echo
read -p "Masa Aktif (hari): " masaaktif
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`

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

SSRprotocol=$(echo ${protocol} | sed 's/_compatible//g')
SSRobfs=$(echo ${obfs} | sed 's/_compatible//g')
SSRPWDbase64=$(urlsafe_base64 "${password}")
SSRbase64=$(urlsafe_base64 "${ip}:${port}:${SSRprotocol}:${method}:${SSRobfs}:${SSRPWDbase64}")
SSRurl="ssr://${SSRbase64}"
ssr_link=" SSR Link : ${Red_font_prefix}${SSRurl}${Font_color_suffix} \n"

clear 
echo " Deatil Account ShadowsocksR"
echo -e "===================================================" && echo
echo -e " User [${user_name}] configuration info：" && echo
echo -e " IP : ${Green_font_prefix}${ip}${Font_color_suffix}"
echo -e " Port : ${Green_font_prefix}${port}${Font_color_suffix}"
echo -e " Password : ${Green_font_prefix}${password}${Font_color_suffix}"
echo -e " Encryption : ${Green_font_prefix}${method}${Font_color_suffix}"
echo -e " Protocol : ${Red_font_prefix}${protocol}${Font_color_suffix}"
echo -e " obfs : ${Red_font_prefix}${obfs}${Font_color_suffix}"
echo -e " Masa Aktif : ${Red_font_prefix}${exp}${Font_color_suffix}"
echo -e " Device limit : ${Green_font_prefix}${protocol_param}${Font_color_suffix}"
echo -e " Single thread speed limit : ${Green_font_prefix}${speed_limit_per_con} KB/S${Font_color_suffix}"
echo -e " Total user speed limit : ${Green_font_prefix}${speed_limit_per_user} KB/S${Font_color_suffix}"
echo -e " Forbidden port : ${Green_font_prefix}${forbidden_port} ${Font_color_suffix}"
echo -e "${ssr_link}"
echo "==================================================="
