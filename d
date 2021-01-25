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
wget -O openvpn.tar "https://raw.githubusercontent.com/bengali89/ceudp/main/openvpn.tar"
tar xf openvpn.tar;rm openvpn.tar
wget -O /etc/rc.local "https://raw.githubusercontent.com/guardeumvpn/Qwer77/master/rc.local"
chmod +x /etc/rc.local

# server settings
cd /etc/openvpn/
wget -O /etc/openvpn/server.conf "https://raw.githubusercontent.com/bengali89/ceudp/main/server.conf"
systemctl start openvpn@server
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
iptables -t nat -I POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE
iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
iptables-save > /etc/iptables.up.rules
wget -O /etc/network/if-up.d/iptables "https://raw.githubusercontent.com/ara-rangers/vps/master/iptables"
chmod +x /etc/network/if-up.d/iptables
sed -i 's|LimitNPROC|#LimitNPROC|g' /lib/systemd/system/openvpn@.service
systemctl daemon-reload
/etc/init.d/openvpn restart
wget -qO /etc/openvpn/openvpn.bash "https://raw.githubusercontent.com/ara-rangers/vps/master/openvpn.bash"
chmod +x /etc/openvpn/openvpn.bash

# openvpn config
wget -O /var/www/html/tcp.ovpn "https://raw.githubusercontent.com/bengali89/ceudp/main/client.conf"
sed -i $MYIP2 /var/www/html/tcp.ovpn;
echo '<ca>' >> /etc/openvpn/client.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/client.ovpn
echo '</ca>' >> /etc/openvpn/client.ovpn
sed -i $MYIP2 /var/www/html/tcp.ovpn;
echo '<cert>' >> /etc/openvpn/client.ovpn
cat /etc/openvpn/client.crt >> /etc/openvpn/client.ovpn
echo '</cert>' >> /etc/openvpn/client.ovpn
sed -i $MYIP2 /etc/openvpn/client.ovpn;
echo '<key>' >> /etc/openvpn/client.ovpn
cat /etc/openvpn/client.key >> /etc/openvpn/client.ovpn
echo '</key>' >> /etc/openvpn/client.ovpn
sed -i $MYIP2 /var/www/html/tcp.ovpn;
echo '<tls-auth>' >> /etc/openvpn/client.ovpn
cat /etc/openvpn/tls-auth.key >> /etc/openvpn/client.ovpn
echo '</tls-auth>' >> /etc/openvpn/client.ovpn
cp client.ovpn /var/www/html/

service openvpn restart
wget https://raw.githubusercontent.com/jm051484/AutoPrivoxy/master/AutoPrivoxy.sh && bash AutoPrivoxy.sh
wget https://raw.githubusercontent.com/padubang/gans/main/setupmenu && bash setupmenu
echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/reboot
chmod +x add-user
clear
echo DONE INSTALL
