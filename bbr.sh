#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: Debian/Ubuntu
#	Description: TCP-BBR
#	Version: 1.0.22
#	Author: Toyo
#	Blog: https://doub.io/wlzy-16/
#=================================================

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[informasi]${Font_color_suffix}"
Error="${Red_font_prefix}[kesalahan]${Font_color_suffix}"
Tip="${Green_font_prefix}[catatan]${Font_color_suffix}"
filepath=$(cd "$(dirname "$0")"; pwd)
file=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')

check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} Akun non-ROOT saat ini (atau tanpa izin ROOT), tidak dapat terus beroperasi, harap ubah akun ROOT atau gunakan ${Green_background_prefix}sudo su${Font_color_suffix} Perintah untuk mendapatkan izin ROOT sementara (Anda mungkin diminta memasukkan kata sandi akun saat ini setelah eksekusi)。" && exit 1
}
#Periksa sistemnya
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
}
Set_latest_new_version(){
	echo -e "Silakan masukkan versi kernel Linux (BBR) untuk mengunduh dan menginstal ${Green_font_prefix}[ Format: x.xx.xx, misalnya: 4.9.96 ]${Font_color_suffix}
${Tip} Silakan buka di sini untuk daftar versi kernel：${Green_font_prefix}[ http://kernel.ubuntu.com/~kernel-ppa/mainline/ ]${Font_color_suffix}
Direkomendasikan untuk digunakan${Green_font_prefix}Versi stabil: 4.9.XX ${Font_color_suffix}，4.9 Versi di atas termasuk versi beta, versi stabil dan versi beta diperbarui secara bersamaan, tidak ada perbedaan dalam akselerasi BBR。"
	read -e -p "(Masuk langsung untuk mendapatkan versi stabil terbaru secara otomatis):" latest_version
	[[ -z "${latest_version}" ]] && get_latest_new_version
	echo
}
# Sumber kode versi terbaru paragraf ini adalah dari: https://teddysun.com/489.html
get_latest_new_version(){
	echo -e "${Info} Periksa versi terbaru dari kernel stabil..."
	latest_version=$(wget -qO- -t1 -T2 "http://kernel.ubuntu.com/~kernel-ppa/mainline/" | awk -F'\"v' '/v4.9.*/{print $2}' |grep -v '\-rc'| cut -d/ -f1 | sort -V | tail -1)
	[[ -z ${latest_version} ]] && echo -e "${Error} Gagal mendeteksi versi terbaru dari kernel !" && exit 1
	echo -e "${Info} Versi terbaru dari kernel stabil adalah : ${latest_version}"
}
get_latest_version(){
	Set_latest_new_version
	bit=`uname -m`
	if [[ ${bit} == "x86_64" ]]; then
		deb_name=$(wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-image" | grep "generic" | awk -F'\">' '/amd64.deb/{print $2}' | cut -d'<' -f1 | head -1 )
		deb_kernel_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${deb_name}"
		deb_kernel_name="linux-image-${latest_version}-amd64.deb"
	else
		deb_name=$(wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-image" | grep "generic" | awk -F'\">' '/i386.deb/{print $2}' | cut -d'<' -f1 | head -1)
		deb_kernel_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${deb_name}"
		deb_kernel_name="linux-image-${latest_version}-i386.deb"
	fi
}
#Periksa apakah kernel memenuhi
check_deb_off(){
	get_latest_new_version
	deb_ver=`dpkg -l|grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep '[4-9].[0-9]*.'`
	latest_version_2=$(echo "${latest_version}"|grep -o '\.'|wc -l)
	if [[ "${latest_version_2}" == "1" ]]; then
		latest_version="${latest_version}.0"
	fi
	if [[ "${deb_ver}" != "" ]]; then
		if [[ "${deb_ver}" == "${latest_version}" ]]; then
			echo -e "${Info} Versi kernel saat ini terdeteksi[${deb_ver}] Persyaratan sudah terpenuhi, lanjutkan..."
		else
			echo -e "${Tip} Versi kernel saat ini terdeteksi[${deb_ver}] Dukungan untuk membuka BBR tetapi bukan versi kernel terbaru, Anda dapat menggunakan${Green_font_prefix} bash ${file}/bbr.sh ${Font_color_suffix}Datang untuk mengupgrade kernel! (Catatan: kernel yang lebih baru tidak lebih baik. Kernel versi 4.9 ke atas saat ini dalam versi beta, dan stabilitas tidak dijamin. Jika versi lama digunakan tanpa masalah, disarankan untuk tidak mengupgrade！)"
		fi
	else
		echo -e "${Error} Versi kernel saat ini terdeteksi[${deb_ver}] BBR tidak didukung, harap gunakan${Green_font_prefix} bash ${file}/bbr.sh ${Font_color_suffix}Untuk mengganti kernel terbaru !" && exit 1
	fi
}
# Hapus inti yang tersisa
del_deb(){
	deb_total=`dpkg -l | grep linux-image | awk '{print $2}' | grep -v "${latest_version}" | wc -l`
	if [[ "${deb_total}" -ge "1" ]]; then
		echo -e "${Info} terdeteksi ${deb_total} Inti yang tersisa, mulai hapus penginstalan..."
		for((integer = 1; integer <= ${deb_total}; integer++))
		do
			deb_del=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${latest_version}" | head -${integer}`
			echo -e "${Info} Mulai hapus instalan ${deb_del} Inti..."
			apt-get purge -y ${deb_del}
			echo -e "${Info} Copot pemasangan ${deb_del} Penghapusan kernel selesai, lanjutkan..."
		done
		deb_total=`dpkg -l|grep linux-image | awk '{print $2}' | wc -l`
		if [[ "${deb_total}" = "1" ]]; then
			echo -e "${Info} Setelah kernel dibongkar, lanjutkan..."
		else
			echo -e "${Error} Pengecualian penghapusan kernel, harap periksa !" && exit 1
		fi
	else
		echo -e "${Info} Terdeteksi bahwa tidak ada kernel yang redundan kecuali kernel yang baru diinstal, lewati langkah menghapus instalan kernel yang berlebihan !"
	fi
}
del_deb_over(){
	del_deb
	update-grub
	addsysctl
	echo -e "${Tip} Setelah VPS restart, silahkan jalankan script untuk mengecek apakah BBR sudah di-load secara normal, jalankan perintahnya： ${Green_background_prefix} bash ${file}/bbr.sh status ${Font_color_suffix}"
	read -e -p "Anda perlu me-restart VPS sebelum BBR bisa dihidupkan, apakah akan restart sekarang ? [Y/n] :" yn
	[[ -z "${yn}" ]] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "${Info} VPS dimulai ulang..."
		reboot
	fi
}
# 安装BBR
installbbr(){
	check_root
	get_latest_version
	deb_ver=`dpkg -l|grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep '[4-9].[0-9]*.'`
	latest_version_2=$(echo "${latest_version}"|grep -o '\.'|wc -l)
	if [[ "${latest_version_2}" == "1" ]]; then
		latest_version="${latest_version}.0"
	fi
	if [[ "${deb_ver}" != "" ]]; then	
		if [[ "${deb_ver}" == "${latest_version}" ]]; then
			echo -e "${Info} Versi kernel saat ini terdeteksi[${deb_ver}] Ini adalah versi terbaru, tidak perlu melanjutkan !"
			deb_total=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${latest_version}" | wc -l`
			if [[ "${deb_total}" != "0" ]]; then
				echo -e "${Info} Jumlah inti yang tidak normal terdeteksi, ada inti yang berlebihan, dan penghapusan dimulai..."
				del_deb_over
			else
				exit 1
			fi
		else
			echo -e "${Info} Terdeteksi bahwa versi kernel saat ini mendukung pengaktifan BBR tetapi bukan versi kernel terbaru, dan mulai memutakhirkan (atau menurunkan) kernel..."
		fi
	else
		echo -e "${Info} Terdeteksi bahwa versi kernel saat ini tidak mendukung pengaktifan BBR, start..."
		virt=`virt-what`
		if [[ -z ${virt} ]]; then
			apt-get update && apt-get install virt-what -y
			virt=`virt-what`
		fi
		if [[ ${virt} == "openvz" ]]; then
			echo -e "${Error} BBR tidak mendukung virtualisasi OpenVZ (penggantian kernel tidak didukung) !" && exit 1
		fi
	fi
	echo "nameserver 8.8.8.8" > /etc/resolv.conf
	echo "nameserver 8.8.4.4" >> /etc/resolv.conf
	
	wget -O "${deb_kernel_name}" "${deb_kernel_url}"
	if [[ -s ${deb_kernel_name} ]]; then
		echo -e "${Info} Paket penginstalan kernel berhasil diunduh, dan penginstalan kernel dimulai..."
		dpkg -i ${deb_kernel_name}
		rm -rf ${deb_kernel_name}
	else
		echo -e "${Error} Download paket instalasi kernel gagal, silakan periksa !" && exit 1
	fi
	#Tentukan apakah kernel berhasil diinstal
	deb_ver=`dpkg -l | grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep "${latest_version}"`
	if [[ "${deb_ver}" != "" ]]; then
		echo -e "${Info} Deteksi bahwa kernel telah berhasil diinstal, mulailah menghapus instalan kernel yang tersisa..."
		del_deb_over
	else
		echo -e "${Error} Instalasi kernel gagal terdeteksi, silakan periksa !" && exit 1
	fi
}
bbrstatus(){
	check_bbr_status_on=`sysctl net.ipv4.tcp_congestion_control | awk '{print $3}'`
	if [[ "${check_bbr_status_on}" = "bbr" ]]; then
		echo -e "${Info} BBR terdeteksi untuk dihidupkan !"
		# Periksa apakah BBR dimulai
		check_bbr_status_off=`lsmod | grep bbr`
		if [[ "${check_bbr_status_off}" = "" ]]; then
			echo -e "${Error} Terdeteksi bahwa BBR telah dihidupkan tetapi tidak dimulai secara normal, coba gunakan versi kernel yang lebih rendah (mungkin ada masalah kompatibilitas, meskipun BBR dihidupkan dalam konfigurasi kernel, kernel gagal memuat modul BBR ) !"
		else
			echo -e "${Info} BBR telah terdeteksi dan dimulai secara normal !"
		fi
		exit 1
	fi
}
addsysctl(){
	sed -i '/net\.core\.default_qdisc=fq/d' /etc/sysctl.conf
	sed -i '/net\.ipv4\.tcp_congestion_control=bbr/d' /etc/sysctl.conf
	
	echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
	sysctl -p
}
startbbr(){
	check_deb_off
	bbrstatus
	addsysctl
	sleep 1s
	bbrstatus
}
# Matikan BBR
stopbbr(){
	check_deb_off
	sed -i '/net\.core\.default_qdisc=fq/d' /etc/sysctl.conf
	sed -i '/net\.ipv4\.tcp_congestion_control=bbr/d' /etc/sysctl.conf
	sysctl -p
	sleep 1s
	
	read -e -p "Anda perlu me-restart VPS untuk menghentikan BBR sepenuhnya, apakah akan merestartnya sekarang ? [Y/n] :" yn
	[[ -z "${yn}" ]] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "${Info} VPS Memulai kembali..."
		reboot
	fi
}
# Lihat status BBR
statusbbr(){
	check_deb_off
	bbrstatus
	echo -e "${Error} BBR tidak dinyalakan !"
}
check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && echo -e "${Error} Skrip ini tidak mendukung sistem saat ini ${release} !" && exit 1
action=$1
[[ -z $1 ]] && action=install
case "$action" in
	install|start|stop|status)
	${action}bbr
	;;
	*)
	echo "kesalahan masukan !"
	echo "pemakaian: { install | start | stop | status }"
	;;
esac
