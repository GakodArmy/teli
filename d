apt-get update && apt-get upgrade
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
apt-get install openvpn
apt-get install curl
apt-get install apache2
rm /var/www/html/index.html
rm /var/www/html/index.nginx-debian.html
wget https://raw.githubusercontent.com/BangJaguh/cina/main/index.html
cp index.html /var/www/html

apt-get install -y openvpn easy-rsa iptables openssl ca-certificates gnupg
apt-get install -y net-tools
cp -r /usr/share/easy-rsa /etc/openvpn
cd /etc/openvpn
cd easy-rsa
sed -i 's|export KEY_COUNTRY="US"|export KEY_COUNTRY="ID"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_PROVINCE="CA"|export KEY_PROVINCE="ID"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_CITY="SanFrancisco"|export KEY_CITY="ID"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_ORG="Fort-Funston"|export KEY_ORG="HunterNblz"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_EMAIL="me@myhost.mydomain"|export KEY_EMAIL="admin@nabil.my.id"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU="MyOrganizationalUnit"|export KEY_OU="HunterNblz"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_NAME="EasyRSA"|export KEY_NAME="HunterNblz"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU=changeme|export KEY_OU=HunterNblz|' /etc/openvpn/easy-rsa/vars
cp openssl-1.0.0.cnf openssl.cnf
source ./vars
./clean-all
source vars
rm -rf keys
./clean-all
./build-ca
./build-key-server server
./pkitool --initca
./pkitool --server server
./pkitool client
./build-dh
# generate ta.key
openvpn --genkey --secret keys/ta.key
cp keys/ca.crt /etc/openvpn
cp keys/server.crt /etc/openvpn
cp keys/server.key /etc/openvpn
cp keys/dh2048.pem /etc/openvpn
cp keys/client.key /etc/openvpn
cp keys/client.crt /etc/openvpn
cp keys/ta.key /etc/openvpn

echo 'port 443
proto tcp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
persist-key
persist-tun
keepalive 10 120
duplicate-cn
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
client-cert-not-required
username-as-common-name
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
comp-lzo
status server-tcp-1194.log
verb 3' >/etc/openvpn/server-tcp-1194.conf

echo 'port 9994
proto tcp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
persist-key
persist-tun
keepalive 10 120
duplicate-cn
server 10.9.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
client-cert-not-required
username-as-common-name
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
comp-lzo
status server-tcp-9994.log
verb 3' >/etc/openvpn/server-tcp-9994.conf

echo 'port 25000
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
persist-key
persist-tun
keepalive 10 120
duplicate-cn
server 20.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
client-cert-not-required
username-as-common-name
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
comp-lzo
status server-udp-25000.log
verb 3' >/etc/openvpn/server-udp-25000.conf

systemctl enable openvpn
service openvpn restart
cd

echo "client
dev tun
proto tcp
remote $MYIP 443
http-proxy-retry
http-proxy $MYIP 8080
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3

" >/var/www/html/client-tcp-1194.ovpn

echo "client
dev tun
proto tcp
remote $MYIP 9994
http-proxy-retry
http-proxy $MYIP 8080
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3

" >/var/www/html/client-tcp-9994.ovpn

echo "client
dev tun
proto udp
remote $MYIP 25000
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3

" >/var/www/html/client-udp-25000.ovpn

echo "client
dev tun
proto tcp
remote $MYIP 2905
http-proxy-retry
http-proxy $MYIP 8080
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3

" >/var/www/html/client-ssl-2905.ovpn

echo "client
dev tun
proto tcp
remote $MYIP 9443
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3

" >/var/www/html/client-ssl-9443.ovpn

echo "client
dev tun
proto tcp
remote $MYIP 1194
http-proxy $MYIP 8080
http-proxy-option CUSTOM-HEADER CONNECT HTTP/1.1
http-proxy-option CUSTOM-HEADER Host m.instagram.com
http-proxy-option CUSTOM-HEADER X-Online-Host m.instagram.com
http-proxy-option CUSTOM-HEADER X-Forward-Host m.instagram.com
http-proxy-option CUSTOM-HEADER Connection Keep-Alive
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3

" >/var/www/html/instagram.ovpn

cd
apt-get install -y zip
cd /var/www/html

{
echo "<ca>"
cat "/etc/openvpn/ca.crt"
echo "</ca>"
echo "<cert>"
cat "/etc/openvpn/server.crt"
echo "</cert>"
echo "<key>"
cat "/etc/openvpn/server.key"
echo "</key>"
} >>client-tcp-1194.ovpn

{
echo "<ca>"
cat "/etc/openvpn/ca.crt"
echo "</ca>"
echo "<cert>"
cat "/etc/openvpn/server.crt"
echo "</cert>"
echo "<key>"
cat "/etc/openvpn/server.key"
echo "</key>"
} >>client-tcp-9994.ovpn

{
echo "<ca>"
cat "/etc/openvpn/ca.crt"
echo "</ca>"
echo "<cert>"
cat "/etc/openvpn/server.crt"
echo "</cert>"
echo "<key>"
cat "/etc/openvpn/server.key"
echo "</key>"
} >>client-ssl-9443.ovpn

{
echo "<ca>"
cat "/etc/openvpn/ca.crt"
echo "</ca>"
echo "<cert>"
cat "/etc/openvpn/server.crt"
echo "</cert>"
echo "<key>"
cat "/etc/openvpn/server.key"
echo "</key>"
} >>client-ssl-2905.ovpn

{
echo "<ca>"
cat "/etc/openvpn/ca.crt"
echo "</ca>"
echo "<cert>"
cat "/etc/openvpn/server.crt"
echo "</cert>"
echo "<key>"
cat "/etc/openvpn/server.key"
echo "</key>"
} >>client-udp-25000.ovpn

{
echo "<ca>"
cat "/etc/openvpn/ca.crt"
echo "</ca>"
echo "<cert>"
cat "/etc/openvpn/server.crt"
echo "</cert>"
echo "<key>"
cat "/etc/openvpn/server.key"
echo "</key>"
} >>instagram.ovpn

zip client-config.zip client-tcp-1194.ovpn client-tcp-9994.ovpn client-ssl-9443.ovpn client-ssl-2905.ovpn client-udp-25000.ovpn instagram.ovpn
apt-get install -y iptables iptables-persistent netfilter-persistent
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $NIC -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.9.0.0/24 -o $NIC -j MASQUERADE
iptables -t nat -A POSTROUTING -s 20.8.0.0/24 -o $NIC -j MASQUERADE
iptables-save > /etc/iptables/rules.v4
service openvpn restart
wget https://raw.githubusercontent.com/jm051484/AutoPrivoxy/master/AutoPrivoxy.sh && bash AutoPrivoxy.sh
wget https://raw.githubusercontent.com/padubang/gans/main/setupmenu && bash setupmenu
echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/reboot
chmod +x add-user
clear
echo DONE INSTALL
