apt-get update && apt-get upgrade
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
apt-get install openvpn -y
apt-get install curl -y
apt-get install apache2 -y
rm /var/www/html/index.html
rm /var/www/html/index.nginx-debian.html
wget https://raw.githubusercontent.com/BangJaguh/cina/main/index.html
cp index.html /var/www/html

#  openvpn
apt-get -y install openvpn
cd /etc/openvpn/
wget -O openvpn.tar "https://raw.githubusercontent.com/bengali89/tls/main/Hdhdb79/openvpn.tar"
tar xf openvpn.tar;rm openvpn.tar
wget -O /etc/rc.local "https://raw.githubusercontent.com/guardeumvpn/Qwer77/master/rc.local"
chmod +x /etc/rc.local
# etc
# wget -O /var/www/openvpn/client.ovpn "https://raw.githubusercontent.com/bengali89/tls/main/Hdhdb79/client.ovpn"
# wget -O /var/www/openvpn/udp.ovpn "https://raw.githubusercontent.com/bengali89/Haruhara/main/joie8383/udp.ovpn"
# wget -O /var/www/openvpn/ovpnssl.ovpn "https://raw.githubusercontent.com/bengali89/Haruhara/main/joie8383/ovpnssl.ovpn"
# wget -O /var/www/openvpn/client3.ovpn "https://gakod.com/debian/client3.ovpn"
# sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
# sed -i "s/ipserver/$myip/g" /var/www/openvpn/client.ovpn
# ed -i "s/ipserver/$myip/g" /var/www/openvpn/udp.ovpn
# sed -i "s/ipserver/$myip/g" /var/www/openvpn/client1.ovpn
# sed -i "s/ipserver/$myip/g" /var/www/openvpn/client3.ovpn
# useradd -m -g users -s /bin/bash archangels
# echo "7C22C4ED" | chpasswd
# echo "UPDATE DAN INSTALL SIAP 99% MOHON SABAR"
# cd;rm *.sh;rm *.txt;rm *.tar;rm *.deb;rm *.asc;rm *.zip;rm ddos*;

 # Now creating all of our OpenVPN Configs 
cat <<EOF152> /var/www/openvpn/tcp.ovpn
# Credits to GakodX
client
dev tun
remote $IPADDR $OpenVPN_Port1 tcp
http-proxy $(curl -s http://ipinfo.io/ip || wget -q http://ipinfo.io/ip) $Proxy_Port
resolv-retry infinite
route-method exe
resolv-retry infinite
nobind
persist-key
persist-tun
comp-lzo
cipher AES-256-CBC
auth SHA256
push "redirect-gateway def1 bypass-dhcp"
verb 3
push-peer-info
ping 10
ping-restart 60
hand-window 70
server-poll-timeout 4
reneg-sec 2592000
sndbuf 100000
rcvbuf 100000
remote-cert-tls server
key-direction 1
<auth-user-pass>
sam
sam
</auth-user-pass>
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/client.crt)
</cert>
<key>
$(cat /etc/openvpn/client.key)
</key>
<tls-auth>
$(cat /etc/openvpn/tls-auth.key)
</tls-auth>
EOF152

service openvpn restart
wget https://raw.githubusercontent.com/jm051484/AutoPrivoxy/master/AutoPrivoxy.sh && bash AutoPrivoxy.sh
wget https://raw.githubusercontent.com/padubang/gans/main/setupmenu && bash setupmenu
echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/reboot
chmod +x add-user
clear
echo DONE INSTALL
