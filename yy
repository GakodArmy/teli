#!/bin/bash
# Debian 9 and 10 VPS Installer
# Script by Gakods
# 
# Illegal selling and redistribution of this script is strictly prohibited
# Please respect author's Property
# Binigay sainyo ng libre, ipamahagi nyo rin ng libre.
#
#

#############################
#############################

#L2TP SCRIPT DEBIAN AND UBUNTU
wget -q 'https://raw.githubusercontent.com/lodixyruss1/LODIxyrussL2TP/master/l2tp_debuntu.sh' && chmod +x l2tp_debuntu.sh && ./l2tp_debuntu.sh

#TO ADD USERS
wget -q 'https://raw.githubusercontent.com/lodixyruss1/LODIxyrussL2TP/master/add_vpn_user.sh' && chmod +x add_vpn_user.sh && ./add_vpn_user.sh

#TO UPDATE ALL USERS
wget -q 'https://raw.githubusercontent.com/lodixyruss1/LODIxyrussL2TP/master/update_vpn_users.sh' && chmod +x update_vpn_users.sh && ./update_vpn_users.sh

# Variables (Can be changed depends on your preferred values)
# Script name
MyScriptName='LODIxyrussScript'

# OpenSSH Ports
SSH_Port1='22'
SSH_Port2='225'

# Your SSH Banner
SSH_Banner='https://fakenetvpn.com/raw/amy_script_banner.json'

# Dropbear Ports
Dropbear_Port1='844'
Dropbear_Port2='843'

# Stunnel Ports
Stunnel_Port1='445' # through Dropbear
Stunnel_Port2='444' # through OpenSSH
Stunnel_Port3='448' # through OpenVPN

# OpenVPN Ports
OpenVPN_Port1='443'
OpenVPN_Port2='1194' # take note when you change this port, openvpn sun noload config will not work

# Privoxy Ports (must be 1024 or higher)
Privoxy_Port1='8118'
Privoxy_Port2='9090'
# OpenVPN Config Download Port
OvpnDownload_Port='81' # Before changing this value, please read this document. It contains all unsafe ports for Google Chrome Browser, please read from line #23 to line #89: https://chromium.googlesource.com/chromium/src.git/+/refs/heads/master/net/base/port_util.cc

# Server local time
MyVPS_Time='Asia/Kuala_Lumpur'
#############################


#############################
#############################
## All function used for this script
#############################
## WARNING: Do not modify or edit anything
## if you did'nt know what to do.
## This part is too sensitive.
#############################
#############################

function InstUpdates(){
 export DEBIAN_FRONTEND=noninteractive
 apt-get update
 apt-get upgrade -y
 
 # Removing some firewall tools that may affect other services
 #apt-get remove --purge ufw firewalld -y

 
 # Installing some important machine essentials
 apt-get install nano wget curl zip unzip tar gzip p7zip-full bc rc openssl cron net-tools dnsutils dos2unix screen bzip2 ccrypt -y
 
 # Now installing all our wanted services
 apt-get install dropbear stunnel4 privoxy ca-certificates nginx ruby apt-transport-https lsb-release squid screenfetch -y

 # Installing all required packages to install Webmin
 apt-get install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python dbus libxml-parser-perl -y
 apt-get install shared-mime-info jq -y
 
 # Installing a text colorizer
 gem install lolcat

 # Trying to remove obsolette packages after installation
 apt-get autoremove -y
 
 # Installing OpenVPN by pulling its repository inside sources.list file 
 #rm -rf /etc/apt/sources.list.d/openvpn*
 echo "deb http://build.openvpn.net/debian/openvpn/stable $(lsb_release -sc) main" >/etc/apt/sources.list.d/openvpn.list && apt-key del E158C569 && wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add -
 wget -qO security-openvpn-net.asc "https://keys.openpgp.org/vks/v1/by-fingerprint/F554A3687412CFFEBDEFE0A312F5F7B42F2B01E7" && gpg --import security-openvpn-net.asc
 apt-get update -y
 apt-get install openvpn -y
}

function InstWebmin(){
 # Download the webmin .deb package
 # You may change its webmin version depends on the link you've loaded in this variable(.deb file only, do not load .zip or .tar.gz file):
 WebminFile='http://prdownloads.sourceforge.net/webadmin/webmin_1.910_all.deb'
 wget -qO webmin.deb "$WebminFile"
 
 # Installing .deb package for webmin
 dpkg --install webmin.deb
 
 rm -rf webmin.deb
 
 # Configuring webmin server config to use only http instead of https
 sed -i 's|ssl=1|ssl=0|g' /etc/webmin/miniserv.conf
 
 # Then restart to take effect
 systemctl restart webmin
}

function InstSSH(){
 # Removing some duplicated sshd server configs
 rm -f /etc/ssh/sshd_config*
 
 # Creating a SSH server config using cat eof tricks
 cat <<'MySSHConfig' > /etc/ssh/sshd_config
# My OpenSSH Server config
Port myPORT1
Port myPORT2
AddressFamily inet
ListenAddress 0.0.0.0
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
PermitRootLogin yes
MaxSessions 1024
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
ClientAliveInterval 240
ClientAliveCountMax 2
UseDNS no
Banner /etc/banner
AcceptEnv LANG LC_*
Subsystem   sftp  /usr/lib/openssh/sftp-server
MySSHConfig

 # Now we'll put our ssh ports inside of sshd_config
 sed -i "s|myPORT1|$SSH_Port1|g" /etc/ssh/sshd_config
 sed -i "s|myPORT2|$SSH_Port2|g" /etc/ssh/sshd_config

 # Download our SSH Banner
 rm -f /etc/banner
 wget -qO /etc/banner "$SSH_Banner"
 dos2unix -q /etc/banner

 # My workaround code to remove `BAD Password error` from passwd command, it will fix password-related error on their ssh accounts.
 sed -i '/password\s*requisite\s*pam_cracklib.s.*/d' /etc/pam.d/common-password
 sed -i 's/use_authtok //g' /etc/pam.d/common-password

 # Some command to identify null shells when you tunnel through SSH or using Stunnel, it will fix user/pass authentication error on HTTP Injector, KPN Tunnel, eProxy, SVI, HTTP Proxy Injector etc ssh/ssl tunneling apps.
 sed -i '/\/bin\/false/d' /etc/shells
 sed -i '/\/usr\/sbin\/nologin/d' /etc/shells
 echo '/bin/false' >> /etc/shells
 echo '/usr/sbin/nologin' >> /etc/shells
 
 # Restarting openssh service
 systemctl restart ssh
 
 # Removing some duplicate config file
 rm -rf /etc/default/dropbear*
 
 # creating dropbear config using cat eof tricks
 cat <<'MyDropbear' > /etc/default/dropbear
# My Dropbear Config
NO_START=0
DROPBEAR_PORT=PORT01
DROPBEAR_EXTRA_ARGS="-p PORT02"
DROPBEAR_BANNER="/etc/banner"
DROPBEAR_RSAKEY="/etc/dropbear/dropbear_rsa_host_key"
DROPBEAR_DSSKEY="/etc/dropbear/dropbear_dss_host_key"
DROPBEAR_ECDSAKEY="/etc/dropbear/dropbear_ecdsa_host_key"
DROPBEAR_RECEIVE_WINDOW=65536
MyDropbear

 # Now changing our desired dropbear ports
 sed -i "s|PORT01|$Dropbear_Port1|g" /etc/default/dropbear
 sed -i "s|PORT02|$Dropbear_Port2|g" /etc/default/dropbear
 
 # Restarting dropbear service
 systemctl restart dropbear
}

function InsStunnel(){
 StunnelDir=$(ls /etc/default | grep stunnel | head -n1)

 # Creating stunnel startup config using cat eof tricks
cat <<'MyStunnelD' > /etc/default/$StunnelDir
# My Stunnel Config
ENABLED=1
FILES="/etc/stunnel/*.conf"
OPTIONS=""
BANNER="/etc/banner"
PPP_RESTART=0
# RLIMITS="-n 4096 -d unlimited"
RLIMITS=""
MyStunnelD

 # Removing all stunnel folder contents
 rm -rf /etc/stunnel/*
 
 # Creating stunnel certifcate using openssl
 openssl req -new -x509 -days 9999 -nodes -subj "/C=PH/ST=NCR/L=Manila/O=$MyScriptName/OU=$MyScriptName/CN=$MyScriptName" -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem &> /dev/null
##  > /dev/null 2>&1

 # Creating stunnel server config
 cat <<'MyStunnelC' > /etc/stunnel/stunnel.conf
# My Stunnel Config
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
TIMEOUTclose = 0

[dropbear]
accept = Stunnel_Port1
connect = 127.0.0.1:dropbear_port_c

[openssh]
accept = Stunnel_Port2
connect = 127.0.0.1:openssh_port_c

[openvpn]
accept = 448
connect = 127.0.0.1:443
MyStunnelC

 # setting stunnel ports
 sed -i "s|Stunnel_Port1|$Stunnel_Port1|g" /etc/stunnel/stunnel.conf
 sed -i "s|dropbear_port_c|$(netstat -tlnp | grep -i dropbear | awk '{print $4}' | cut -d: -f2 | xargs | awk '{print $2}' | head -n1)|g" /etc/stunnel/stunnel.conf
 sed -i "s|Stunnel_Port2|$Stunnel_Port2|g" /etc/stunnel/stunnel.conf
 sed -i "s|openssh_port_c|$(netstat -tlnp | grep -i ssh | awk '{print $4}' | cut -d: -f2 | xargs | awk '{print $2}' | head -n1)|g" /etc/stunnel/stunnel.conf

 # Restarting stunnel service
 systemctl restart $StunnelDir

}

function InsOpenVPN(){
 # Checking if openvpn folder is accidentally deleted or purged
 if [[ ! -e /etc/openvpn ]]; then
  mkdir -p /etc/openvpn
 fi

 # Removing all existing openvpn server files
 rm -rf /etc/openvpn/*

 # Creating server.conf, ca.crt, server.crt and server.key
 cat <<'myOpenVPNconf1' > /etc/openvpn/server_tcp.conf
# LODIxyrussScript

port MyOvpnPort1
proto tcp
dev tun
dev-type tun
sndbuf 100000
rcvbuf 100000
crl-verify crl.pem
ca ca.crt
cert server.crt
key server.key
tls-auth tls-auth.key 0
dh dh.pem
topology subnet
server 10.9.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
cipher AES-256-CBC
auth SHA256
comp-lzo
user nobody
group nogroup
persist-tun
status openvpn-status.log
verb 2
mute 3
plugin /etc/openvpn/openvpn-auth-pam.so /etc/pam.d/login
verify-client-cert none
username-as-common-name
myOpenVPNconf1
cat <<'myOpenVPNconf2' > /etc/openvpn/server_udp.conf
# LODIxyrussScript

port MyOvpnPort2
dev tun
proto udp
dev tun
user nobody
group nogroup
persist-key
persist-tun
keepalive 10 120
topology subnet
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "dhcp-option DNS 1.0.0.1"
push "dhcp-option DNS 1.1.1.1"
push "redirect-gateway def1 bypass-dhcp" 
crl-verify crl.pem
ca ca.crt
cert server.crt
key server.key
tls-auth tls-auth.key 0
dh dh.pem
auth SHA256
cipher AES-128-CBC
tls-server
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-128-GCM-SHA256
status openvpn.log
verb 3
plugin /etc/openvpn/openvpn-auth-pam.so /etc/pam.d/login
username-as-common-name
myOpenVPNconf2
 cat <<'EOF7'> /etc/openvpn/ca.crt
-----BEGIN CERTIFICATE-----
MIIDVDCCAjygAwIBAgIUUZx2hyFj1NP/HlSye43fEx71aqwwDQYJKoZIhvcNAQEL
BQAwGTEXMBUGA1UEAwwOdnBuLmY1bGFicy5kZXYwHhcNMjEwMTE0MDI0OTQxWhcN
MzEwMTEyMDI0OTQxWjAZMRcwFQYDVQQDDA52cG4uZjVsYWJzLmRldjCCASIwDQYJ
KoZIhvcNAQEBBQADggEPADCCAQoCggEBALGs+GFrp7+dPlhmxUP0nVqY1Na3sb+/
NUcAdncurs6hBzqOuDlTx7ZcWRNBbrgPvzHTYJGBaYiSlOrt7h2dghBEpDq1OP29
9wpMHhRgheSrsmFL5GfuCs+SyJi34wq/D3b09vmlhecGcK5n8QzcNEiacTVRCia9
TbvPXBZvyDY4trSEuKnTsL/r1UcacDJuPAZ7UoJbEZrxZu6xqLHFP/yr99y6X2qz
joGZlBx4pId2pAnfb1rcqAb5tvXxHXNK0EyUgMCwdHS+aVtmXJfj9wZlk3Z+8b7f
BhwURApWTcFz70gwEYmArIY5w49TMHcNIAN+AumYv/SJNOgt2oeE8k8CAwEAAaOB
kzCBkDAdBgNVHQ4EFgQU/Ga3V1iPk7I6YR5DeNQuQ+9e5DUwVAYDVR0jBE0wS4AU
/Ga3V1iPk7I6YR5DeNQuQ+9e5DWhHaQbMBkxFzAVBgNVBAMMDnZwbi5mNWxhYnMu
ZGV2ghRRnHaHIWPU0/8eVLJ7jd8THvVqrDAMBgNVHRMEBTADAQH/MAsGA1UdDwQE
AwIBBjANBgkqhkiG9w0BAQsFAAOCAQEAThvfXeUiYDGumhn4ILOxm1y7ZT3EUhtT
iDaThgKfSYjTLvuG9uTMC3DmZUjC/JXRW0g2waY9/MMJ7+3VUolsaaxLe+233jc5
uqKlmMBWalXBJCVapAoGSVviyiTP0VTxlaprVgbgrWT6oScoMwHFq6+MS5FW3MhU
wVrvF2ed4bDFc4hwr2UEp2aNxpl8veGewhqNhUVZLTnm9FeJ9mLCLWvZvWA/8dpn
4yyYPnSeLub6qM4KuWdD+LKxO7/kj1QhOi7aSx3NrE/G3iKl5afttgrOq8VATdMM
j/N7c5oIS2l/ID5us17zVJT9tA0OQlOWp3JlnFmm/9q2VWvpKh/mSQ==
-----END CERTIFICATE-----
EOF7
 cat <<'EOF9'> /etc/openvpn/client.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            3b:80:8e:a6:3a:d9:39:e4:ff:e0:0f:04:0f:bb:ad:dd
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=vpn.f5labs.dev
        Validity
            Not Before: Jan 14 02:53:35 2021 GMT
            Not After : Apr 19 02:53:35 2023 GMT
        Subject: CN=client.f5labs.dev
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:d0:db:2a:46:68:84:d4:9c:0a:a3:33:40:37:f2:
                    f4:60:dd:7a:e5:5d:c0:c2:49:35:bb:9c:18:98:8c:
                    79:41:42:d9:2d:c4:e7:83:95:ef:65:ae:9c:a5:80:
                    3b:be:22:85:7a:38:81:70:64:0d:49:88:77:87:6a:
                    9d:12:6c:17:28:84:55:97:b4:f7:b3:fd:ec:dc:b8:
                    16:43:01:3c:06:f3:3b:f7:c6:c0:00:8b:c8:bd:03:
                    1f:cf:ef:3b:fa:a7:7e:4f:3a:ec:15:e3:b5:b7:ed:
                    3f:38:9f:3d:8c:4f:02:4e:d8:b6:85:1d:2c:f1:37:
                    f8:b6:3d:08:14:6f:57:5d:17:3f:40:4b:e3:05:0d:
                    39:34:7f:4e:b4:e7:0c:e1:95:56:ae:2b:7b:ab:d4:
                    26:69:5e:27:c3:81:58:cb:79:40:5e:d5:70:52:97:
                    fd:8d:8f:89:3f:61:a1:ff:5f:54:05:e9:6c:54:e4:
                    f4:ca:ac:d4:3a:fa:78:dd:27:e8:68:c4:3c:89:54:
                    3d:92:7d:f8:aa:64:d3:3b:e0:b5:c1:95:10:58:78:
                    87:8f:c3:4c:37:3d:a0:76:36:a8:22:00:f2:c2:fc:
                    19:6e:7f:18:41:fe:70:71:e3:c5:ef:96:da:d9:b8:
                    80:5f:1b:98:4f:81:f0:c0:4c:9f:38:d1:bf:1e:07:
                    7e:e7
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 Subject Key Identifier: 
                FC:2C:7A:13:E6:8B:6E:2E:6B:B3:D9:47:4C:A6:4E:18:11:EA:26:4B
            X509v3 Authority Key Identifier: 
                keyid:FC:66:B7:57:58:8F:93:B2:3A:61:1E:43:78:D4:2E:43:EF:5E:E4:35
                DirName:/CN=vpn.f5labs.dev
                serial:51:9C:76:87:21:63:D4:D3:FF:1E:54:B2:7B:8D:DF:13:1E:F5:6A:AC

            X509v3 Extended Key Usage: 
                TLS Web Client Authentication
            X509v3 Key Usage: 
                Digital Signature
    Signature Algorithm: sha256WithRSAEncryption
         57:33:02:49:cb:42:0f:82:7a:d8:bb:54:d8:36:d1:ad:4d:a0:
         8f:5a:3f:7d:49:0f:4b:2f:22:bd:08:5c:9e:78:79:e9:8c:0e:
         1a:d9:54:08:58:98:23:b6:0b:53:7d:f8:4c:fe:63:63:3d:74:
         74:d8:3f:84:f4:91:4a:65:11:41:cd:6b:1b:ea:d2:50:df:f0:
         c3:d5:07:88:c2:7d:45:fb:9a:59:56:02:c5:17:f5:13:86:e2:
         a8:db:1c:61:33:f3:53:26:51:a6:a2:9e:9d:4a:71:b1:01:bd:
         0e:70:2a:a1:5d:7c:37:eb:81:40:f3:0b:c6:ce:be:39:83:2b:
         53:d0:0f:54:51:90:31:3c:9e:ba:ec:d9:46:6c:98:ab:b9:ca:
         7c:56:71:c6:74:0b:b5:30:98:8d:e7:eb:e4:0d:cf:f4:43:28:
         09:63:f5:12:67:4a:1d:0f:cf:61:4d:c7:2e:6e:21:9f:09:62:
         06:1f:16:8b:a0:8d:2f:fa:a5:16:52:41:57:29:ac:99:4e:a4:
         4a:0f:76:4a:80:9b:88:1f:05:e9:9b:90:da:75:f3:bc:fa:c5:
         86:b2:70:95:05:24:74:50:b2:3a:ab:f7:05:84:22:93:11:d5:
         c9:00:48:4c:40:84:d4:7b:30:17:35:9b:02:d9:a3:79:c6:ab:
         16:fe:b4:de
-----BEGIN CERTIFICATE-----
MIIDZTCCAk2gAwIBAgIQO4COpjrZOeT/4A8ED7ut3TANBgkqhkiG9w0BAQsFADAZ
MRcwFQYDVQQDDA52cG4uZjVsYWJzLmRldjAeFw0yMTAxMTQwMjUzMzVaFw0yMzA0
MTkwMjUzMzVaMBwxGjAYBgNVBAMMEWNsaWVudC5mNWxhYnMuZGV2MIIBIjANBgkq
hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0NsqRmiE1JwKozNAN/L0YN165V3Awkk1
u5wYmIx5QULZLcTng5XvZa6cpYA7viKFejiBcGQNSYh3h2qdEmwXKIRVl7T3s/3s
3LgWQwE8BvM798bAAIvIvQMfz+87+qd+TzrsFeO1t+0/OJ89jE8CTti2hR0s8Tf4
tj0IFG9XXRc/QEvjBQ05NH9OtOcM4ZVWrit7q9QmaV4nw4FYy3lAXtVwUpf9jY+J
P2Gh/19UBelsVOT0yqzUOvp43SfoaMQ8iVQ9kn34qmTTO+C1wZUQWHiHj8NMNz2g
djaoIgDywvwZbn8YQf5wcePF75ba2biAXxuYT4HwwEyfONG/Hgd+5wIDAQABo4Gl
MIGiMAkGA1UdEwQCMAAwHQYDVR0OBBYEFPwsehPmi24ua7PZR0ymThgR6iZLMFQG
A1UdIwRNMEuAFPxmt1dYj5OyOmEeQ3jULkPvXuQ1oR2kGzAZMRcwFQYDVQQDDA52
cG4uZjVsYWJzLmRldoIUUZx2hyFj1NP/HlSye43fEx71aqwwEwYDVR0lBAwwCgYI
KwYBBQUHAwIwCwYDVR0PBAQDAgeAMA0GCSqGSIb3DQEBCwUAA4IBAQBXMwJJy0IP
gnrYu1TYNtGtTaCPWj99SQ9LLyK9CFyeeHnpjA4a2VQIWJgjtgtTffhM/mNjPXR0
2D+E9JFKZRFBzWsb6tJQ3/DD1QeIwn1F+5pZVgLFF/UThuKo2xxhM/NTJlGmop6d
SnGxAb0OcCqhXXw364FA8wvGzr45gytT0A9UUZAxPJ667NlGbJirucp8VnHGdAu1
MJiN5+vkDc/0QygJY/USZ0odD89hTccubiGfCWIGHxaLoI0v+qUWUkFXKayZTqRK
D3ZKgJuIHwXpm5DadfO8+sWGsnCVBSR0ULI6q/cFhCKTEdXJAEhMQITUezAXNZsC
2aN5xqsW/rTe
-----END CERTIFICATE-----
EOF9
 cat <<'EOF10'> /etc/openvpn/client.key
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDQ2ypGaITUnAqj
M0A38vRg3XrlXcDCSTW7nBiYjHlBQtktxOeDle9lrpylgDu+IoV6OIFwZA1JiHeH
ap0SbBcohFWXtPez/ezcuBZDATwG8zv3xsAAi8i9Ax/P7zv6p35POuwV47W37T84
nz2MTwJO2LaFHSzxN/i2PQgUb1ddFz9AS+MFDTk0f0605wzhlVauK3ur1CZpXifD
gVjLeUBe1XBSl/2Nj4k/YaH/X1QF6WxU5PTKrNQ6+njdJ+hoxDyJVD2SffiqZNM7
4LXBlRBYeIePw0w3PaB2NqgiAPLC/BlufxhB/nBx48XvltrZuIBfG5hPgfDATJ84
0b8eB37nAgMBAAECggEBALNUe+gYtnUXxsp6pxljMxI5Gdz3sxsfYVPFpBjYBQVU
MMZr253Qj83vL/GrOaD4Y0OeYQXv4rjQxFEx6cx3oyrW9eddK5MQ5OBf8D14QeJ1
13fY3+OYIrSoihgwgn+mcX32SeBBtTZIL5CeqmpfLMwmqBGEC6LTPGq93MIvGASE
84Lf28gVk69nPdj3ZHw7zjG5Rb5gmnVnj8HeiYKixFG7Ev0ttdczZ9g+XmEoCLDo
XQFUjgrllrJSJpV1GK1N4fntrDSrZ+GyM2R9dNcpgSEZ077QdIljjqHcfHgABjkB
Asbcjb0cQy9aIE3BwOkh39FPM71pcnRcXVlJsuGTIgECgYEA9ySHXI52hfqmMt1B
u/grY0LUb+mUrLh2GKAOPTzzN2zTzvBy6b7DvKbTmsOTiMVQ2j3rVIw/qLrIm4wg
TNoCIBBkM/gJ4MtbaR0tWhE8CIG//OiN+bVSIuojZ+6csNo4EgpXRhosaX5n9gw6
JWpCGGELKYkzBoqXMxALxYTDh1cCgYEA2Fdd5f/c9gYeMsUiKUxCq4PDZS6aNBO+
w5zxWGc7+gDJDTg3Cue4g65KYHm16ZCWLZittaV6xjcAU8hsgIq5mR/9nwd1DiFy
kmot5JWkQc23yqseq2lHwDKRCc6Fh77zpvt80WI5iD6v7kc4P1JViZtLJpVC1Rxi
JMzO8gzT2vECgYAQARmS8NbUDks89/8NwSBuKSHArYunM7rSFWtWo9/MMwv0VrXa
VTQvv03ss8WWEdEOkPvwWbS1pILhL83XrDZ/BRC4HNPm7sRYpj8NmhgdJOnd4uFu
zkMnZ6orTNRwz3DaGjlUnNVLb5gj4t7RFXR6R66FXhEj1027TMq2W8aduQKBgQCw
VR2ivxaxrLDmfslmUdMxixczHHXxpnphZEVO4e3/yq4UyVIL4G0DX4cd9XYxZnkR
txU3LibQ8rmgkIbniqrWRT3qZiChoN+KuWKootOcEvoQBcPcwNYLsOuIy70ItLpR
yz+kRmRQSZAKLiCJdClmHJ53V0d+/kB8cDbpEU2IcQKBgCZCfKbUevhQ37iN1AJZ
tNDQjCed/MMhcBQBCkWXin5lxgyctIPgZiNlk2w7nooNWFAYymKJ6HuAtetOYssS
i0AXVmVVagNwIw7b5Q5Z2jGBQ0W5H1s6qQ832zTlokWuwVpzq2HpGPIq0P5z4Omb
UG4rLe+2IINXbG3ry8s254N5
-----END PRIVATE KEY-----
EOF10
 cat <<'EOF18'> /etc/openvpn/tls-auth.key
#
# 2048 bit OpenVPN static key
#
-----BEGIN OpenVPN Static key V1-----
930c4ccae2e0713f1b1b83821ba956e8
a22ac9824f01af42cc816ceb4a12afa0
ccabb752d5d62c97aaabb2c0a8d7f0b8
081f4fe2c9af33ad1ebb32b85e6d5471
11675bc0af428b38d427852ef2694da9
3cffc4535040e6fd02498c986a5fb9e2
6ac4b411288481114cb83695052cb8ea
0c9763c1ff28316f42da1aae62516d27
b32a9ab71e85f47b07e4be5dd8113553
f212f49d018b0c9d95a1329fd864935f
b3f24a270322a7abe617cb85817d3fc2
d2f2d9030c6d24ccbb8911047bef97c9
294463a9d98c5f59654f74e7a8eb4af6
175a3ffbc5cbc384137c52f0ef01a1f4
f20dbce3ba0a5f18d4ff9d952583b846
6dc7f535bacd958427d3e61ab3a512d1
-----END OpenVPN Static key V1-----
EOF18
 cat <<'EOF107'> /etc/openvpn/server.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            46:f7:43:78:91:24:bc:19:66:7f:0e:84:08:c1:f1:69
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=vpn.f5labs.dev
        Validity
            Not Before: Jan 14 02:51:17 2021 GMT
            Not After : Apr 19 02:51:17 2023 GMT
        Subject: CN=vpn.f5labs.dev
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:de:42:c3:78:d2:f2:96:f4:03:78:ed:ca:45:19:
                    73:74:28:88:69:73:48:10:c7:12:9c:22:3e:09:41:
                    7b:87:d5:fc:b6:ef:11:4d:15:97:ca:d9:7e:b2:90:
                    aa:97:ec:5f:56:2b:76:60:e4:e4:25:e6:b5:96:7a:
                    d2:80:86:cc:fc:41:dc:45:6d:ae:1a:78:f0:21:54:
                    79:61:78:22:f1:3d:54:f9:d9:13:d3:0e:4c:38:71:
                    65:85:6a:f2:22:31:d6:59:f5:51:82:18:23:ea:d5:
                    13:f5:b7:43:5d:a7:f7:9e:e3:59:8f:ea:cc:6a:a2:
                    89:e8:de:79:d9:57:7e:03:a5:2d:f8:3e:19:ac:b8:
                    3c:2f:cf:4a:a7:62:b0:11:22:b0:ec:9b:5e:38:cb:
                    db:f0:b3:d4:47:7e:7d:97:42:6b:91:36:2e:e5:be:
                    9c:9a:9c:9b:c2:14:99:c4:49:a9:0d:1a:98:5b:b7:
                    a1:37:03:82:be:9f:e5:1e:43:b1:08:f8:46:6f:f3:
                    77:13:11:5a:9f:d2:d4:f9:c7:92:e4:55:75:27:35:
                    18:55:5d:ef:87:b0:fa:46:f4:d1:c4:a5:4d:f8:e2:
                    2a:b8:ba:22:e7:57:ec:fe:93:88:61:e4:e9:ec:c3:
                    c1:52:4d:88:61:a5:e4:8c:4b:5a:99:01:6c:6c:ff:
                    d9:61
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 Subject Key Identifier: 
                65:2A:ED:A2:C4:CF:21:2B:EE:CD:7E:53:D8:EE:DA:77:AD:FF:56:46
            X509v3 Authority Key Identifier: 
                keyid:FC:66:B7:57:58:8F:93:B2:3A:61:1E:43:78:D4:2E:43:EF:5E:E4:35
                DirName:/CN=vpn.f5labs.dev
                serial:51:9C:76:87:21:63:D4:D3:FF:1E:54:B2:7B:8D:DF:13:1E:F5:6A:AC

            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
            X509v3 Key Usage: 
                Digital Signature, Key Encipherment
            X509v3 Subject Alternative Name: 
                DNS:vpn.f5labs.dev
    Signature Algorithm: sha256WithRSAEncryption
         21:d9:86:a5:ca:99:07:2c:ef:17:b5:45:ba:ae:4f:a0:a8:c6:
         81:ca:b4:b1:6c:45:b8:f1:23:5a:9c:4a:e1:ee:9a:b6:34:b0:
         7d:d2:69:4d:54:69:7a:e4:1f:11:0a:fd:73:6e:4a:e5:cf:35:
         28:09:93:2c:7c:ff:9d:53:8d:3a:e4:cf:cb:08:21:a2:be:ae:
         c5:ed:f6:d3:43:c4:92:3c:5a:65:86:c3:26:86:b7:0f:8f:24:
         08:38:d4:b2:59:d0:dc:8e:ed:ca:ac:65:06:9e:84:0b:bb:13:
         ef:1c:e8:94:63:a7:e4:ff:43:d0:ed:8f:ab:bf:63:0f:09:b2:
         87:17:24:ec:c2:9e:2d:a5:fa:70:d8:17:16:ab:46:39:86:84:
         bb:90:63:3f:3b:55:22:30:ac:ec:c7:1a:b0:19:af:72:9e:5a:
         a2:64:39:66:e4:79:cc:14:d6:9d:a1:32:9a:0f:2a:42:e2:32:
         4f:f4:3d:65:bf:9f:8c:6f:1b:d2:a5:22:e3:34:ce:84:c0:43:
         a6:c9:e0:7f:6f:fc:24:5a:02:b1:41:bc:30:e2:0c:2f:48:74:
         c0:f1:71:2b:15:e4:8c:cc:c9:da:e0:ba:b8:f9:b4:12:a2:0b:
         5a:c3:2a:7b:84:41:95:17:31:9d:7c:6d:50:cb:15:9f:bf:a2:
         b1:be:cf:bf
-----BEGIN CERTIFICATE-----
MIIDfTCCAmWgAwIBAgIQRvdDeJEkvBlmfw6ECMHxaTANBgkqhkiG9w0BAQsFADAZ
MRcwFQYDVQQDDA52cG4uZjVsYWJzLmRldjAeFw0yMTAxMTQwMjUxMTdaFw0yMzA0
MTkwMjUxMTdaMBkxFzAVBgNVBAMMDnZwbi5mNWxhYnMuZGV2MIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3kLDeNLylvQDeO3KRRlzdCiIaXNIEMcSnCI+
CUF7h9X8tu8RTRWXytl+spCql+xfVit2YOTkJea1lnrSgIbM/EHcRW2uGnjwIVR5
YXgi8T1U+dkT0w5MOHFlhWryIjHWWfVRghgj6tUT9bdDXaf3nuNZj+rMaqKJ6N55
2Vd+A6Ut+D4ZrLg8L89Kp2KwESKw7JteOMvb8LPUR359l0JrkTYu5b6cmpybwhSZ
xEmpDRqYW7ehNwOCvp/lHkOxCPhGb/N3ExFan9LU+ceS5FV1JzUYVV3vh7D6RvTR
xKVN+OIquLoi51fs/pOIYeTp7MPBUk2IYaXkjEtamQFsbP/ZYQIDAQABo4HAMIG9
MAkGA1UdEwQCMAAwHQYDVR0OBBYEFGUq7aLEzyEr7s1+U9ju2net/1ZGMFQGA1Ud
IwRNMEuAFPxmt1dYj5OyOmEeQ3jULkPvXuQ1oR2kGzAZMRcwFQYDVQQDDA52cG4u
ZjVsYWJzLmRldoIUUZx2hyFj1NP/HlSye43fEx71aqwwEwYDVR0lBAwwCgYIKwYB
BQUHAwEwCwYDVR0PBAQDAgWgMBkGA1UdEQQSMBCCDnZwbi5mNWxhYnMuZGV2MA0G
CSqGSIb3DQEBCwUAA4IBAQAh2YalypkHLO8XtUW6rk+gqMaByrSxbEW48SNanErh
7pq2NLB90mlNVGl65B8RCv1zbkrlzzUoCZMsfP+dU4065M/LCCGivq7F7fbTQ8SS
PFplhsMmhrcPjyQIONSyWdDcju3KrGUGnoQLuxPvHOiUY6fk/0PQ7Y+rv2MPCbKH
FyTswp4tpfpw2BcWq0Y5hoS7kGM/O1UiMKzsxxqwGa9ynlqiZDlm5HnMFNadoTKa
DypC4jJP9D1lv5+MbxvSpSLjNM6EwEOmyeB/b/wkWgKxQbww4gwvSHTA8XErFeSM
zMna4Lq4+bQSogtawyp7hEGVFzGdfG1QyxWfv6Kxvs+/
-----END CERTIFICATE-----
EOF107
 cat <<'EOF113'> /etc/openvpn/server.key
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDeQsN40vKW9AN4
7cpFGXN0KIhpc0gQxxKcIj4JQXuH1fy27xFNFZfK2X6ykKqX7F9WK3Zg5OQl5rWW
etKAhsz8QdxFba4aePAhVHlheCLxPVT52RPTDkw4cWWFavIiMdZZ9VGCGCPq1RP1
t0Ndp/ee41mP6sxqoono3nnZV34DpS34PhmsuDwvz0qnYrARIrDsm144y9vws9RH
fn2XQmuRNi7lvpyanJvCFJnESakNGphbt6E3A4K+n+UeQ7EI+EZv83cTEVqf0tT5
x5LkVXUnNRhVXe+HsPpG9NHEpU344iq4uiLnV+z+k4hh5Onsw8FSTYhhpeSMS1qZ
AWxs/9lhAgMBAAECggEBAM4YFm2ZHb1/8yBVTvQYD4isdSFi9nYoQkdpMSEgCU4B
zN5MfDyAQ0qjtuoZXzaUxip/Drv2QuAqOEObDEqFtNpMr9XpSEHf1rrxO8R3w97y
QjOTaOCSJ3dHHx5B9thiYiL0aWo6vENq5aE5GExmDiTVKB1dWcOfiEXY1iAFEyKI
c989eHcS+D9KY5tNhRRUJboUeMpytaJSs1jxRU2W8xnVaAJ7dzNkgH9a9GRrQN8j
ehyteuQG0H3AMT3jODaavozgz0GiEGYPUs39a2pWSqUh1SLPJx94WIlIjERNLORk
atZiyBZt+TIIRaf5uOoEYgcECvjgfkmJZg3zXhQXkakCgYEA8C7zGOiTEJ7pfPwE
GDvRx1iVvOPvKhMc2xrUyk3UQTqfH9xZaWGAOYwK9i6MsTgybXtwUSaQ8cPhqCjg
gu+tHwzGWErZQ0BqqtN+AWpbkkbJbxOhZY2jQmVXaBR5CMdhwV+AWEv9F9Lbxerv
BULjMhcP2si/CgsTEs6PN5tSZtsCgYEA7OWr/siyewxf9xSjQ++Ht9oGtqBlbVsZ
Qx2YlEuYNEslgSGg4I9LKS5y55ZhRWai4+BOOSZWY+b3XYNiS4U3asppvTMP4tUi
LmPs3kGlenT/QuNFlW6z7kjRs5t9y8eMkFy/xGJKZY22swl+kC9i0kxx5cofxPP0
pyq7Wpdvf3MCgYBeAdJOVoFxSPGUZMNphMhX4PlCpGgwrKhnrbnJsOq52Sr8+m7Y
izv3yjNkJdYVayx5o43ThWfH6OZCvjUZqpu1AngDiNA+vVDCqeKwxSMwPpqK6kEK
kYRr8WRjrVeuMvO1Dx8Z8CwQjgxNC+Yfxg1MxrAC7v2u/aSqgMSXfCilbwKBgA6s
+8bA8C2nSpqn8KVYxXOiUiAmN6Jarmn1/2nQdRFoRl6Fks3WkrVuZzfpnQULorOz
RaVMtrVhrZlhdklva0t2Vq6d5zIKOh/dmOL79iBr9xRRuBHV1dfBMxyJWXWyWwbm
eArWe/1mlhbpU6njBaA5lCTELMuqwVFJ2Gl4UDP5AoGAJWCTpUftWEFHkGLDN1Zs
bzchAN6mXKKqr9Jg12xkgt8sVKNn+ntA5bJi9Ib7n1lafyIQ8Gn1h6kG76OY02PP
/CDy368Q8XPzxrNLueJDNeS5JBNGXKkjqz3pc/c2CQ0QBxv1ar9RNa2AZxr2k5Ii
jNGLcR0Tmt2DaoPHClr/D8Y=
-----END PRIVATE KEY-----
EOF113
 cat <<'EOF13'> /etc/openvpn/dh.pem
-----BEGIN DH PARAMETERS-----
MIICCAKCAgEA4n16aZpGsqucktU0QAkocQGie3E0rjbaanO+8HWea4Uf6XvKokA+
iXZl/pPHg/ItVjkFZViWMzZ9Xa0/Y2JKVuYCnguC8xSdN+xlo2gQ+PwK1ExrB0lR
PoCWa/KzJIQI5VWHNUDh0qkdmGgpxfAIKNZXzbxW3ktZi1oX0TI8vPFejbtWEGoE
H4HDhF6376o2NvHPILEVNzmWp9hRpmU+luxFQaoDD5iDkrpL1zdGvBhmGilYQwRo
0jt5uIm6N/S/jFvwMhn4QFKaDOppFwTwH+sH9/EiDH93xlmGv6B5SiI2aP1w1YKj
ytDXm680EMzfYP1XYcd/6u+9xHI1BsJAWvcjOhPujAUy8krWe/+PjpYypLwx9gj7
zuHxsyrGvt8xPyRJfNbRn5Bvw4T+7RMbHGUehdy40qORJ4+ahd/+MhW/RDgx1EBf
njX9j2mSXEHW8AlEQlGaEDiUQqKZQmYDvkVMfjgl7c4HJxRSK/bl5UqLY6n1m744
fHzoDeQYl57JKTpgz026Gs/XXiZptI9H+fEHjHHcKgEreOA7tDiiqgrNvkPsRB+L
j2UJ0Ap3iVdPtCGii39p6i3B8jRnRiFcGoT+W15zjwEwD/tl699hZc1IMdeAod27
n7VpX6UPkLnqGE3HWh8eDnFndCYS+OKoRtIQZoJkzJA/Lq3o1YCdjFMCAQI=
-----END DH PARAMETERS-----
EOF13
 cat <<'EOF103'> /etc/openvpn/crl.pem
-----BEGIN X509 CRL-----
MIIBvDCBpQIBATANBgkqhkiG9w0BAQsFADAZMRcwFQYDVQQDDA52cG4uZjVsYWJz
LmRldhcNMjEwMTE0MDI1MTIzWhcNMzEwMTEyMDI1MTIzWqBYMFYwVAYDVR0jBE0w
S4AU/Ga3V1iPk7I6YR5DeNQuQ+9e5DWhHaQbMBkxFzAVBgNVBAMMDnZwbi5mNWxh
YnMuZGV2ghRRnHaHIWPU0/8eVLJ7jd8THvVqrDANBgkqhkiG9w0BAQsFAAOCAQEA
qv7+B4WNPqRI4WAiTnCtE/vQlQeKnn39NvDEbjfpJjNZAadQxaTeYtO58TOCu5R4
qwF42g0E2mUQvwUEmUeVulnDjEz5e6KOkgllWsrZGwlUObuKNNKrCHqvXxbH/rHk
76/4Jfu7IvqTk4a9c+MV5r5eSA7plRzdJhqgkBWCmD/46UlP2imkgNGg4FeAamuc
kiLEVXPwjRK30L3uUcWXzvXmXtLlvaadPHKPS5YA41WKS0xZ9iELIz0eUHXl8pgd
jrZFH4tMHWZ+mBTRA/76xsbBGWtkxND932g1vAc281EHv9+4iyW1SdvUTJNzZObh
6GJJ6ESQE6h3vJJpVeoFCg==
-----END X509 CRL-----
EOF103

 # Getting all dns inside resolv.conf then use as Default DNS for our openvpn server
 #grep -v '#' /etc/resolv.conf | grep 'nameserver' | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | while read -r line; do
	#echo "push \"dhcp-option DNS $line\"" >> /etc/openvpn/server_tcp.conf
#done
 #grep -v '#' /etc/resolv.conf | grep 'nameserver' | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | while read -r line; do
	#echo "push \"dhcp-option DNS $line\"" >> /etc/openvpn/server_udp.conf
#done

 # setting openvpn server port
 sed -i "s|MyOvpnPort1|$OpenVPN_Port1|g" /etc/openvpn/server_tcp.conf
 sed -i "s|MyOvpnPort2|$OpenVPN_Port2|g" /etc/openvpn/server_udp.conf
 
 # Generating openvpn dh.pem file using openssl
 #openssl dhparam -out /etc/openvpn/dh.pem 1024
 
 # Getting some OpenVPN plugins for unix authentication
 wget -qO /etc/openvpn/b.zip 'https://raw.githubusercontent.com/GakodArmy/teli/main/openvpn_plugin64'
 unzip -qq /etc/openvpn/b.zip -d /etc/openvpn
 rm -f /etc/openvpn/b.zip
 
 # Some workaround for OpenVZ machines for "Startup error" openvpn service
 if [[ "$(hostnamectl | grep -i Virtualization | awk '{print $2}' | head -n1)" == 'openvz' ]]; then
 sed -i 's|LimitNPROC|#LimitNPROC|g' /lib/systemd/system/openvpn*
 systemctl daemon-reload
fi

 # Allow IPv4 Forwarding
 echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/20-openvpn.conf && sysctl --system &> /dev/null && echo 1 > /proc/sys/net/ipv4/ip_forward

 # Iptables Rule for OpenVPN server
 #PUBLIC_INET="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"
 #IPCIDR='10.200.0.0/16'
 #iptables -I FORWARD -s $IPCIDR -j ACCEPT
 #iptables -t nat -A POSTROUTING -o $PUBLIC_INET -j MASQUERADE
 #iptables -t nat -A POSTROUTING -s $IPCIDR -o $PUBLIC_INET -j MASQUERADE
 
 # Installing Firewalld
 apt install firewalld -y
 systemctl start firewalld
 systemctl enable firewalld
 firewall-cmd --quiet --set-default-zone=public
 firewall-cmd --quiet --zone=public --permanent --add-port=1-65534/tcp
 firewall-cmd --quiet --zone=public --permanent --add-port=1-65534/udp
 firewall-cmd --quiet --reload
 firewall-cmd --quiet --add-masquerade
 firewall-cmd --quiet --permanent --add-masquerade
 firewall-cmd --quiet --permanent --add-service=ssh
 firewall-cmd --quiet --permanent --add-service=openvpn
 firewall-cmd --quiet --permanent --add-service=http
 firewall-cmd --quiet --permanent --add-service=https
 firewall-cmd --quiet --permanent --add-service=privoxy
 firewall-cmd --quiet --permanent --add-service=squid
 firewall-cmd --quiet --reload
 
 # Enabling IPv4 Forwarding
 echo 1 > /proc/sys/net/ipv4/ip_forward
 
 # Starting OpenVPN server
 systemctl start openvpn@server_tcp
 systemctl start openvpn@server_udp
 systemctl enable openvpn@server_tcp
 systemctl enable openvpn@server_udp
 systemctl restart openvpn@server_tcp
 systemctl restart openvpn@server_udp
 
 # Pulling OpenVPN no internet fixer script
 #wget -qO /etc/openvpn/openvpn.bash "https://raw.githubusercontent.com/Bonveio/BonvScripts/master/openvpn.bash"
 #0chmod +x /etc/openvpn/openvpn.bash
}

function InsProxy(){
 # Removing Duplicate privoxy config
 rm -rf /etc/privoxy/config*
 
 # Creating Privoxy server config using cat eof tricks
 cat <<'myPrivoxy' > /etc/privoxy/config
# My Privoxy Server Config
user-manual /usr/share/doc/privoxy/user-manual
confdir /etc/privoxy
logdir /var/log/privoxy
filterfile default.filter
logfile logfile
listen-address 0.0.0.0:Privoxy_Port1
listen-address 0.0.0.0:Privoxy_Port2
toggle 1
enable-remote-toggle 0
enable-remote-http-toggle 0
enable-edit-actions 0
enforce-blocks 0
buffer-limit 4096
enable-proxy-authentication-forwarding 1
forwarded-connect-retries 1
accept-intercepted-requests 1
allow-cgi-request-crunching 1
split-large-forms 0
keep-alive-timeout 5
tolerate-pipelining 1
socket-timeout 300
permit-access 0.0.0.0/0 IP-ADDRESS
myPrivoxy

 # Setting machine's IP Address inside of our privoxy config(security that only allows this machine to use this proxy server)
 sed -i "s|IP-ADDRESS|$IPADDR|g" /etc/privoxy/config
 
 # Setting privoxy ports
 sed -i "s|Privoxy_Port1|$Privoxy_Port1|g" /etc/privoxy/config
 sed -i "s|Privoxy_Port2|$Privoxy_Port2|g" /etc/privoxy/config

 # I'm setting Some Squid workarounds to prevent Privoxy's overflowing file descriptors that causing 50X error when clients trying to connect to your proxy server(thanks for this trick @homer_simpsons)
 apt remove --purge squid -y
 rm -rf /etc/squid/sq*
 apt install squid -y
 
# Squid Ports (must be 1024 or higher)
 Proxy_Port1='8000'
 Proxy_Port2='8080'
 Proxy_Port3='3128'
 Proxy_Port4='8888'
 cat <<mySquid > /etc/squid/squid.conf
acl VPN dst $(wget -4qO- http://ipinfo.io/ip)/32
http_access allow VPN
http_access deny all 
http_port 0.0.0.0:$Proxy_Port1
http_port 0.0.0.0:$Proxy_Port2
http_port 0.0.0.0:$Proxy_Port3
http_port 0.0.0.0:$Proxy_Port4
acl all src 0.0.0.0/0
http_access allow all
forwarded_for off
via off
request_header_access Host allow all
request_header_access Content-Length allow all
request_header_access Content-Type allow all
request_header_access All deny all
coredump_dir /var/spool/squid
dns_nameservers 1.1.1.1 1.0.0.1
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
visible_hostname localhost
mySquid

 sed -i "s|SquidCacheHelper|$Privoxy_Port1|g" /etc/squid/squid.conf

 # Starting Proxy server
 echo -e "Restarting proxy server.."
 systemctl restart privoxy
 systemctl restart squid
}

function OvpnConfigs(){
 # Creating nginx config for our ovpn config downloads webserver
 cat <<'myNginxC' > /etc/nginx/conf.d/bonveio-ovpn-config.conf
# My OpenVPN Config Download Directory
server {
 listen 0.0.0.0:myNginx;
 server_name localhost;
 root /var/www/openvpn;
 index index.html;
}
myNginxC

 # Setting our nginx config port for .ovpn download site
 sed -i "s|myNginx|$OvpnDownload_Port|g" /etc/nginx/conf.d/bonveio-ovpn-config.conf

 # Removing Default nginx page(port 80)
 rm -rf /etc/nginx/sites-*

 # Creating our root directory for all of our .ovpn configs
 rm -rf /var/www/openvpn
 mkdir -p /var/www/openvpn
# Now creating all of our OpenVPN Configs 
cat <<EOF152> /var/www/openvpn/GTMConfig.ovpn
client
dev tun
remote $IPADDR $OpenVPN_Port1 tcp
http-proxy $IPADDR 8080
http-proxy-retry
resolv-retry infinite
route-method exe
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

cat <<EOF16> /var/www/openvpn/SunConfig.ovpn
# Credits to GakodX
client
dev tun
proto udp
remote $IPADDR $OpenVPN_Port2
resolv-retry infinite
route-method exe
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
EOF16

cat <<EOF17> /var/www/openvpn/SunNoLoad.ovpn
client
proto tcp-client
dev tun
remote 127.0.0.1 443
route $IPADDR 255.255.255.255 net_gateway 
http-proxy $IPADDR 8080
http-proxy-retry
resolv-retry infinite
route-method exe
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
EOF17

 # Creating OVPN download site index.html
cat <<'mySiteOvpn' > /var/www/openvpn/index.html
<!DOCTYPE html>
<html lang="en">

<!-- OVPN Download site by LODIxyrussScript -->

<head><meta charset="utf-8" /><title>MyScriptName OVPN Config Download</title><meta name="description" content="MyScriptName Server" /><meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" name="viewport" /><meta name="theme-color" content="#000000" /><link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.8.2/css/all.css"><link href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.3.1/css/bootstrap.min.css" rel="stylesheet"><link href="https://cdnjs.cloudflare.com/ajax/libs/mdbootstrap/4.8.3/css/mdb.min.css" rel="stylesheet"></head><body><div class="container justify-content-center" style="margin-top:9em;margin-bottom:5em;"><div class="col-md"><div class="view"><img src="https://openvpn.net/wp-content/uploads/openvpn.jpg" class="card-img-top"><div class="mask rgba-white-slight"></div></div><div class="card"><div class="card-body"><h5 class="card-title">Config List</h5><br /><ul class="list-group"><li class="list-group-item justify-content-between align-items-center" style="margin-bottom:1em;"><p>For Globe/TM <span class="badge light-blue darken-4">Android/iOS/PC/Modem</span><br /><small> For EZ/GS Promo with WNP freebies</small></p><a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/GTMConfig.ovpn" style="float:right;"><i class="fa fa-download"></i> Download</a></li><li class="list-group-item justify-content-between align-items-center" style="margin-bottom:1em;"><p>For Sun <span class="badge light-blue darken-4">Android/iOS/PC/Modem</span><br /><small> For TU UDP Promos</small></p><a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/SunConfig.ovpn" style="float:right;"><i class="fa fa-download"></i> Download</a></li><li class="list-group-item justify-content-between align-items-center" style="margin-bottom:1em;"><p>For Sun <span class="badge light-blue darken-4">Android/iOS/PC/Modem</span><br /><small> Trinet GIGASTORIES Promos</small></p><a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/GStories.ovpn" style="float:right;"><i class="fa fa-download"></i> Download</a></li></ul></div></div></div></div></body></html>
mySiteOvpn
 
 # Setting template's correct name,IP address and nginx Port
 sed -i "s|MyScriptName|$MyScriptName|g" /var/www/openvpn/index.html
 sed -i "s|NGINXPORT|$OvpnDownload_Port|g" /var/www/openvpn/index.html
 sed -i "s|IP-ADDRESS|$IPADDR|g" /var/www/openvpn/index.html

 # Restarting nginx service
 systemctl restart nginx
 
 # Creating all .ovpn config archives
 cd /var/www/openvpn
 zip -qq -r Configs.zip *.ovpn
 cd
}

function ip_address(){
  local IP="$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )"
  [ -z "${IP}" ] && IP="$( wget -qO- -t1 -T2 ipv4.icanhazip.com )"
  [ -z "${IP}" ] && IP="$( wget -qO- -t1 -T2 ipinfo.io/ip )"
  [ ! -z "${IP}" ] && echo "${IP}" || echo
} 
IPADDR="$(ip_address)"

function ConfStartup(){
 # Daily reboot time of our machine
 # For cron commands, visit https://crontab.guru
 echo -e "0 4\t* * *\troot\treboot" > /etc/cron.d/b_reboot_job

 # Creating directory for startup script
 rm -rf /etc/barts
 mkdir -p /etc/barts
 chmod -R 755 /etc/barts
 
 # Creating startup script using cat eof tricks
 cat <<'EOFSH' > /etc/barts/startup.sh
#!/bin/bash
# Setting server local time
ln -fs /usr/share/zoneinfo/MyVPS_Time /etc/localtime

# Prevent DOS-like UI when installing using APT (Disabling APT interactive dialog)
export DEBIAN_FRONTEND=noninteractive

# Allowing ALL TCP ports for our machine (Simple workaround for policy-based VPS)
iptables -A INPUT -s $(wget -4qO- http://ipinfo.io/ip) -p tcp -m multiport --dport 1:65535 -j ACCEPT

# Allowing OpenVPN to Forward traffic
/bin/bash /etc/openvpn/openvpn.bash

# Deleting Expired SSH Accounts
/usr/local/sbin/delete_expired &> /dev/null
EOFSH
 chmod +x /etc/barts/startup.sh
 
 # Setting server local time every time this machine reboots
 sed -i "s|MyVPS_Time|$MyVPS_Time|g" /etc/barts/startup.sh

 # 
 rm -rf /etc/sysctl.d/99*

 # Setting our startup script to run every machine boots 
 echo "[Unit]
Description=Barts Startup Script
Before=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash /etc/barts/startup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/barts.service
 chmod +x /etc/systemd/system/barts.service
 systemctl daemon-reload
 systemctl start barts
 systemctl enable barts &> /dev/null

 # Rebooting cron service
 systemctl restart cron
 systemctl enable cron
 
}

function ConfMenu(){
echo -e " Creating Menu scripts.."

cd /usr/local/sbin/
rm -rf {accounts,base-ports,base-ports-wc,base-script,bench-network,clearcache,connections,create,create_random,create_trial,delete_expired,diagnose,edit_dropbear,edit_openssh,edit_openvpn,edit_ports,edit_squid3,edit_stunnel4,locked_list,menu,options,ram,reboot_sys,reboot_sys_auto,restart_services,server,set_multilogin_autokill,set_multilogin_autokill_lib,show_ports,speedtest,user_delete,user_details,user_details_lib,user_extend,user_list,user_lock,user_unlock}
wget -q 'https://raw.githubusercontent.com/Barts-23/menu1/master/menu.zip'
unzip -qq menu.zip
rm -f menu.zip
chmod +x ./*
dos2unix ./* &> /dev/null
sed -i 's|/etc/squid/squid.conf|/etc/privoxy/config|g' ./*
sed -i 's|http_port|listen-address|g' ./*
cd ~

echo 'clear' > /etc/profile.d/barts.sh
echo 'echo '' > /var/log/syslog' >> /etc/profile.d/barts.sh
echo 'screenfetch -p -A Android' >> /etc/profile.d/barts.sh
chmod +x /etc/profile.d/barts.sh
}

function ScriptMessage(){
 echo -e " (GAKODS) $MyScriptName Debian VPS Installer"
 echo -e " Open release version"
 echo -e ""
 echo -e " Script created by Bonveio"
 echo -e " Edited by LODIxyruss"
}


#############################
#############################
## Installation Process
#############################
## WARNING: Do not modify or edit anything
## if you did'nt know what to do.
## This part is too sensitive.
#############################
#############################

 # (For OpenVPN) Checking it this machine have TUN Module, this is the tunneling interface of OpenVPN server
 if [[ ! -e /dev/net/tun ]]; then
 echo -e "[\e[1;31mÃƒâ€”\e[0m] You cant use this script without TUN Module installed/embedded in your machine, file a support ticket to your machine admin about this matter"
 echo -e "[\e[1;31m-\e[0m] Script is now exiting..."
 exit 1
fi

 # Begin Installation by Updating and Upgrading machine and then Installing all our wanted packages/services to be install.
 ScriptMessage
 sleep 2
 InstUpdates
 
 # Configure OpenSSH and Dropbear
 echo -e "Configuring ssh..."
 InstSSH
 
 # Configure Stunnel
 echo -e "Configuring stunnel..."
 InsStunnel
 
 # Configure Webmin
 echo -e "Configuring webmin..."
 InstWebmin
 
 # Configure Privoxy and Squid
 echo -e "Configuring proxy..."
 InsProxy
 
 # Configure OpenVPN
 echo -e "Configuring OpenVPN..."
 InsOpenVPN
 
 # Configuring Nginx OVPN config download site
 OvpnConfigs

 # Some assistance and startup scripts
 ConfStartup

 # VPS Menu script v1.0
 ConfMenu
 
 # Setting server local time
 ln -fs /usr/share/zoneinfo/$MyVPS_Time /etc/localtime
 
 clear
 cd ~

 # Running sysinfo 
 bash /etc/profile.d/barts.sh
 
 # Showing script's banner message
 ScriptMessage
 
 # Showing additional information from installating this script
 echo -e ""
 echo -e " Success Installation"
 echo -e ""
 echo -e " Service Ports: "
 echo -e " OpenSSH: $SSH_Port1, $SSH_Port2"
 echo -e " Stunnel: $Stunnel_Port1, $Stunnel_Port2"
 echo -e " DropbearSSH: $Dropbear_Port1, $Dropbear_Port2"
 echo -e " Privoxy: $Privoxy_Port1, $Privoxy_Port2"
 echo -e " Squid: $Proxy_Port1, $Proxy_Port2"
 echo -e " OpenVPN: $OpenVPN_Port1, $OpenVPN_Port2"
 echo -e " OpenVPN SSL: $Stunnel_Port3"
 echo -e " NGiNX: $OvpnDownload_Port"
 echo -e " Webmin: 10000"
 echo -e " L2tp IPSec Key: fakenetvpn101"
 echo -e ""
 echo -e ""
 echo -e " OpenVPN Configs Download site"
 echo -e " http://$IPADDR:$OvpnDownload_Port"
 echo -e ""
 echo -e " All OpenVPN Configs Archive"
 echo -e " http://$IPADDR:$OvpnDownload_Port/Configs.zip"
 echo -e ""
 echo -e ""
 echo -e " [Note] DO NOT RESELL THIS SCRIPT"

 # Clearing all logs from installation
 rm -rf /root/.bash_history && history -c && echo '' > /var/log/syslog

rm -f yy*
exit 1
