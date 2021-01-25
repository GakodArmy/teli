#!/bin/bash
# Debian 9 and 10 VPS Installer
# Script by Bonveio Abitona
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
MIIE7jCCA9agAwIBAgIJAJLzuFmEowyMMA0GCSqGSIb3DQEBCwUAMIGqMQswCQYD
VQQGEwJDTjELMAkGA1UECBMCQ0ExFTATBgNVBAcTDFNhbkZyYW5jaXNjbzEVMBMG
A1UEChMMRm9ydC1GdW5zdG9uMRUwEwYDVQQLEwx3d3cuZGluZ2QuY24xGDAWBgNV
BAMTD0ZvcnQtRnVuc3RvbiBDQTEQMA4GA1UEKRMHRWFzeVJTQTEdMBsGCSqGSIb3
DQEJARYOYWRtaW5AZGluZ2QuY24wHhcNMTcwMjIxMDMzNzE4WhcNMjcwMjE5MDMz
NzE4WjCBqjELMAkGA1UEBhMCQ04xCzAJBgNVBAgTAkNBMRUwEwYDVQQHEwxTYW5G
cmFuY2lzY28xFTATBgNVBAoTDEZvcnQtRnVuc3RvbjEVMBMGA1UECxMMd3d3LmRp
bmdkLmNuMRgwFgYDVQQDEw9Gb3J0LUZ1bnN0b24gQ0ExEDAOBgNVBCkTB0Vhc3lS
U0ExHTAbBgkqhkiG9w0BCQEWDmFkbWluQGRpbmdkLmNuMIIBIjANBgkqhkiG9w0B
AQEFAAOCAQ8AMIIBCgKCAQEAxShPTu6oTmHqm1pvvn/qayZ8YF26AFEct1BP8wFB
IPTNxHP66c5jIqOEZjcaMwiKlngfP+cS3A8t47cW8ZZqcDguSOSiiOag+zy2iTH5
HxyHaYiI2pAp55rYlx3QOXwryrBic06edD7JSGNYeXn7kOO8ViJoclOTSCCQTTJB
vqNhifIy35qxcueD075Rz//dAJUhr+QX9ixtK815aSeH2+NyqYwYha3l6Z7KtFgb
8veKdY9TAA4pjVX9I2iVpn+ezQPDxdBDHN4Bc8MmuIErEzVOIUxK3TzXxkSyuCSK
pvDFNKEITcIo2AZiPyw9OxYzfSbT3ilAzoKyEFg/WCXlxwIDAQABo4IBEzCCAQ8w
HQYDVR0OBBYEFCBcOM8ljbd8B+J6Xjwj13iK7fBxMIHfBgNVHSMEgdcwgdSAFCBc
OM8ljbd8B+J6Xjwj13iK7fBxoYGwpIGtMIGqMQswCQYDVQQGEwJDTjELMAkGA1UE
CBMCQ0ExFTATBgNVBAcTDFNhbkZyYW5jaXNjbzEVMBMGA1UEChMMRm9ydC1GdW5z
dG9uMRUwEwYDVQQLEwx3d3cuZGluZ2QuY24xGDAWBgNVBAMTD0ZvcnQtRnVuc3Rv
biBDQTEQMA4GA1UEKRMHRWFzeVJTQTEdMBsGCSqGSIb3DQEJARYOYWRtaW5AZGlu
Z2QuY26CCQCS87hZhKMMjDAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IB
AQBwZvIQU4d7XD1dySjCHej+i5QhK1y2BTrmYSemLnMQp9PT/wQ7bwzZjoO9jTeJ
x2sMfhp0EVQCZvBFGqArNu1Ysh00mMQfWWb8K3LWbmThEkNpwoGniHBgDkPJOITM
rA2HSIh53mkQt5u9H4/vmVWElhGakgEzgfNrzxj6goX5klXxRL/JqAjAJhjS06sS
JPNVSZv0tdE+XaO02sPjK7/KWbwAGf4mO2v71Q+oYJdoRmAcge+gbBMg2s6rPCfv
Bp2g84FhG04f5KyJIVzzQ+0sCx94XE7P5HN/zjO+3QPDd7dxGZ6ia1Z5nnSRSJVa
yBNWh3h8PAaAQQi7qkuJB+iF
-----END CERTIFICATE-----
EOF7
 cat <<'EOF9'> /etc/openvpn/client.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 2 (0x2)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=CN, ST=CA, L=SanFrancisco, O=Fort-Funston, OU=www.dingd.cn, CN=Fort-Funston CA/name=EasyRSA/emailAddress=admin@dingd.cn
        Validity
            Not Before: Feb 21 03:48:14 2017 GMT
            Not After : Feb 19 03:48:14 2027 GMT
        Subject: C=CN, ST=CA, L=SanFrancisco, O=Fort-Funston, OU=www.dingd.cn, CN=client/name=EasyRSA/emailAddress=admin@dingd.cn
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:cd:9a:05:ff:c5:58:cf:49:fb:6c:5b:9b:54:da:
                    b1:6b:52:48:9d:09:1e:53:a7:ca:14:03:31:ff:76:
                    0a:d7:a7:e9:7a:b1:a6:b4:ad:a4:35:a2:b5:62:ee:
                    b0:75:02:8e:6b:93:e5:96:d7:c1:49:04:82:73:0c:
                    7e:11:dc:92:25:3b:7f:0c:30:2b:4c:dd:c0:e1:fb:
                    c8:31:3c:4c:39:eb:1c:1a:8b:28:69:e0:de:3a:02:
                    8b:50:97:71:4e:ea:0a:28:a0:5f:ee:10:d2:39:be:
                    bb:0e:2a:69:ed:f9:f0:ab:6f:e9:9c:e9:fa:83:64:
                    45:22:ac:71:89:b6:70:ab:42:32:22:23:28:cf:b7:
                    b8:2c:04:f9:56:60:2c:45:66:89:c5:1b:4e:55:35:
                    e7:d6:86:92:bd:95:f0:eb:36:53:4c:95:e7:6f:b0:
                    83:e6:20:4d:9c:fc:6b:85:af:50:e4:41:8d:af:7b:
                    fb:f2:c8:af:b8:e2:84:9b:26:99:2a:ed:62:23:76:
                    78:6f:ce:de:2d:6c:08:a0:1e:de:94:50:12:f4:be:
                    20:ee:69:a5:ac:ac:c6:38:2f:13:f3:82:6f:83:62:
                    2e:f6:5c:59:d8:35:10:00:31:a8:38:39:c2:3f:0b:
                    30:dc:9a:05:c5:65:ea:2c:6d:22:67:07:a7:58:29:
                    90:4d
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            Netscape Comment: 
                Easy-RSA Generated Certificate
            X509v3 Subject Key Identifier: 
                C0:A0:80:CC:C7:DB:49:6D:20:18:68:A1:A8:28:A6:52:B4:93:ED:2E
            X509v3 Authority Key Identifier: 
                keyid:20:5C:38:CF:25:8D:B7:7C:07:E2:7A:5E:3C:23:D7:78:8A:ED:F0:71
                DirName:/C=CN/ST=CA/L=SanFrancisco/O=Fort-Funston/OU=www.dingd.cn/CN=Fort-Funston CA/name=EasyRSA/emailAddress=admin@dingd.cn
                serial:92:F3:B8:59:84:A3:0C:8C

            X509v3 Extended Key Usage: 
                TLS Web Client Authentication
            X509v3 Key Usage: 
                Digital Signature
    Signature Algorithm: sha256WithRSAEncryption
         0e:5b:ef:08:87:05:29:b8:58:a9:2e:4f:70:62:fb:a2:f0:0c:
         ef:55:7d:2a:78:77:9f:f9:74:18:b0:7c:a4:58:2a:20:d8:66:
         39:e0:5b:34:af:e1:7c:ab:97:dc:70:40:d2:bc:3a:9e:82:98:
         a0:00:ce:d8:eb:aa:70:e3:be:f6:08:13:75:43:05:bf:2f:58:
         2a:34:d5:6c:2a:b9:c2:65:47:92:ec:03:df:71:57:ba:0e:5f:
         65:a7:52:b6:bb:21:9c:ff:e9:f7:e0:fd:96:ab:1a:66:ed:c8:
         93:3a:ca:e4:8f:d9:86:21:fa:cb:68:34:46:cb:66:11:6b:0f:
         d8:ca:6b:2f:ba:6e:5d:16:1b:ab:ae:fe:e8:36:94:d2:e0:e0:
         19:08:6c:0e:f7:34:ae:8d:7e:af:0b:92:c8:bc:70:d1:ef:e5:
         16:41:90:eb:ea:eb:4a:03:d5:33:ac:63:34:e6:5f:ae:80:30:
         3d:e7:8c:24:2e:82:d0:7c:84:e0:56:e9:22:f0:ea:9a:03:0c:
         2a:41:71:74:44:84:63:18:e0:7d:60:b1:fc:44:15:83:d2:1a:
         48:8b:06:0b:fc:e8:e9:39:49:75:bb:23:cb:7f:e2:5d:13:f5:
         51:3c:f1:42:44:d6:2f:00:6d:18:38:e2:67:d5:a0:54:08:49:
         55:1f:21:a9
-----BEGIN CERTIFICATE-----
MIIFKzCCBBOgAwIBAgIBAjANBgkqhkiG9w0BAQsFADCBqjELMAkGA1UEBhMCQ04x
CzAJBgNVBAgTAkNBMRUwEwYDVQQHEwxTYW5GcmFuY2lzY28xFTATBgNVBAoTDEZv
cnQtRnVuc3RvbjEVMBMGA1UECxMMd3d3LmRpbmdkLmNuMRgwFgYDVQQDEw9Gb3J0
LUZ1bnN0b24gQ0ExEDAOBgNVBCkTB0Vhc3lSU0ExHTAbBgkqhkiG9w0BCQEWDmFk
bWluQGRpbmdkLmNuMB4XDTE3MDIyMTAzNDgxNFoXDTI3MDIxOTAzNDgxNFowgaEx
CzAJBgNVBAYTAkNOMQswCQYDVQQIEwJDQTEVMBMGA1UEBxMMU2FuRnJhbmNpc2Nv
MRUwEwYDVQQKEwxGb3J0LUZ1bnN0b24xFTATBgNVBAsTDHd3dy5kaW5nZC5jbjEP
MA0GA1UEAxMGY2xpZW50MRAwDgYDVQQpEwdFYXN5UlNBMR0wGwYJKoZIhvcNAQkB
Fg5hZG1pbkBkaW5nZC5jbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AM2aBf/FWM9J+2xbm1TasWtSSJ0JHlOnyhQDMf92Cten6XqxprStpDWitWLusHUC
jmuT5ZbXwUkEgnMMfhHckiU7fwwwK0zdwOH7yDE8TDnrHBqLKGng3joCi1CXcU7q
CiigX+4Q0jm+uw4qae358Ktv6Zzp+oNkRSKscYm2cKtCMiIjKM+3uCwE+VZgLEVm
icUbTlU159aGkr2V8Os2U0yV52+wg+YgTZz8a4WvUORBja97+/LIr7jihJsmmSrt
YiN2eG/O3i1sCKAe3pRQEvS+IO5ppaysxjgvE/OCb4NiLvZcWdg1EAAxqDg5wj8L
MNyaBcVl6ixtImcHp1gpkE0CAwEAAaOCAWEwggFdMAkGA1UdEwQCMAAwLQYJYIZI
AYb4QgENBCAWHkVhc3ktUlNBIEdlbmVyYXRlZCBDZXJ0aWZpY2F0ZTAdBgNVHQ4E
FgQUwKCAzMfbSW0gGGihqCimUrST7S4wgd8GA1UdIwSB1zCB1IAUIFw4zyWNt3wH
4npePCPXeIrt8HGhgbCkga0wgaoxCzAJBgNVBAYTAkNOMQswCQYDVQQIEwJDQTEV
MBMGA1UEBxMMU2FuRnJhbmNpc2NvMRUwEwYDVQQKEwxGb3J0LUZ1bnN0b24xFTAT
BgNVBAsTDHd3dy5kaW5nZC5jbjEYMBYGA1UEAxMPRm9ydC1GdW5zdG9uIENBMRAw
DgYDVQQpEwdFYXN5UlNBMR0wGwYJKoZIhvcNAQkBFg5hZG1pbkBkaW5nZC5jboIJ
AJLzuFmEowyMMBMGA1UdJQQMMAoGCCsGAQUFBwMCMAsGA1UdDwQEAwIHgDANBgkq
hkiG9w0BAQsFAAOCAQEADlvvCIcFKbhYqS5PcGL7ovAM71V9Knh3n/l0GLB8pFgq
INhmOeBbNK/hfKuX3HBA0rw6noKYoADO2OuqcOO+9ggTdUMFvy9YKjTVbCq5wmVH
kuwD33FXug5fZadStrshnP/p9+D9lqsaZu3IkzrK5I/ZhiH6y2g0RstmEWsP2Mpr
L7puXRYbq67+6DaU0uDgGQhsDvc0ro1+rwuSyLxw0e/lFkGQ6+rrSgPVM6xjNOZf
roAwPeeMJC6C0HyE4FbpIvDqmgMMKkFxdESEYxjgfWCx/EQVg9IaSIsGC/zo6TlJ
dbsjy3/iXRP1UTzxQkTWLwBtGDjiZ9WgVAhJVR8hqQ==
-----END CERTIFICATE-----
EOF9
 cat <<'EOF10'> /etc/openvpn/client.key
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDNmgX/xVjPSfts
W5tU2rFrUkidCR5Tp8oUAzH/dgrXp+l6saa0raQ1orVi7rB1Ao5rk+WW18FJBIJz
DH4R3JIlO38MMCtM3cDh+8gxPEw56xwaiyhp4N46AotQl3FO6goooF/uENI5vrsO
Kmnt+fCrb+mc6fqDZEUirHGJtnCrQjIiIyjPt7gsBPlWYCxFZonFG05VNefWhpK9
lfDrNlNMledvsIPmIE2c/GuFr1DkQY2ve/vyyK+44oSbJpkq7WIjdnhvzt4tbAig
Ht6UUBL0viDuaaWsrMY4LxPzgm+DYi72XFnYNRAAMag4OcI/CzDcmgXFZeosbSJn
B6dYKZBNAgMBAAECggEAW8Gha8RnHhumWXWInRX8mCjgvzSSlEMNrGDAr4G+1P/a
8ybVf0z/O/ChgsWDerTpWplmnSss16lrjmzE1rPZhURILuhQar2Ml04GyfJfEnoa
0L3KC3aPttPr2Mu9hbptTjREm7pmF99HG8tR+yLQhbIsUBsb8geN0yuigBMrtUHI
1wgP1C0gpbfPWExq7kTTclnHFjDRn2SuAXGRKNrCkMI+3r17TPooq0Tf/3wHxE6o
a3d1eMuVdX50pDJNV7vfkSm4FrJXWaXhj5s7lj5PLsqE9NXA9RWuL73awCjM9PL3
b7HWLi5GGqucvxya8W6S/YZcNFNmhxi/dH+xQuv3AQKBgQDmEOWc9oZrQuxep6qS
TkScfkntAo/F5SeD2fg2NX5hgQAkdFaGcIEqcp49bSb2N/AS8xO5Dowld7AcX6X0
YZYTSWBb4YhcFs2acZDlSJ0EILOabjeX26IAYPt0M83rccy6/+WNq8gydSzzlKOf
MsIEEdikppBe4CXGxfHX6zFNOwKBgQDkxyY9LT7Xq0NF9Hz+1+enVPySMsoyC8jQ
YEJCCnsQyL31G9+k3DnWGAss7/Rnjd9fVryPNpKuqBhFMsJPjVJXs1pfNoRI2Haz
LObxlJNcTED4ONHLD5VjM84j97EKQBQ5ZrKvUwnRJBI5ljNRa26rAW4/jnPWsI5x
XDDtpvjgFwKBgFDSWMeWd0xRG1Z5UlvJcSME3pWLk9RylzojpaXtjvNT7SfhUtAx
z76Iu3xazxgqOIV/rUsSiDtVW6HsHBHJAn7OBTLh/RRU0m/SO5PAuaBMmKvE0nTf
rH6zk0KUPF/c/44l/Y+SbGcFcQA1FHIF09C4MEJPXWJnHf5BZZ9zuUMnAoGAMi1T
v7s6u0a+3IsBF0v3bQYA13f4TP20r69NGPr/fvDoaOgSJzB+JuzjFpoSetvtEBYQ
CUEo7tHDcPnvEE+orb+SpKtqXCfN8QJ6LKYvo+C9pzOfH/BtDXMBVXYwCFWBmg1i
R33o+0v0C1lcLBFqFmub6Kiv03ip5UcZHCaxE0UCgYEAlHzk63DYXtgC6AK47auk
sqfz6c2/6OpvDL3ez9T/RqiLxpdBNjh1zQ9gNwtRC7ijS6DUkvdcXbeweXTT+gXQ
bskMRq1YeuijP9+eVoX4dye92nXLO7cRLUvJINS/VJTQFcfFMWlvc2P5i3FVsvxD
l2Zif9fCaYAfPcUAEazdLjw=
-----END PRIVATE KEY-----
EOF10
 cat <<'EOF18'> /etc/openvpn/tls-auth.key
#
# 2048 bit OpenVPN static key
#
-----BEGIN OpenVPN Static key V1-----
07a0c4fdc79e45b6d7d69abee82a3dca
7026125b063bb19d79ff443ec144dfcd
6df565ad2449cb928a89f2959e32305e
86cc150c1c6e1d24e25bbdbd716b0b34
ce5d92f5c8133812759ca8b10295d624
5e6659dafbbe31fd20971b3287fc3762
555cc9cd10eaf1b2570339295ded9e61
cbce6d29bd8e5c7d4aea86027beb8d3c
323a5dc803ef5d574b8d5c08a981ca8d
3754d34a7d60896b295823cde4bb6ab7
57757ab750b06352b7a218d6814ae433
4a6b1570cb680cd854aad74196cda45b
b69acb97de87f1ec6cc01a2034bd7e8c
3e0ffea1cccf722716bcf387e56baf04
369dde778a5544ada640c15c65ec5389
2ba0834a78302fab9b214bfc3dddd80e
-----END OpenVPN Static key V1-----
EOF18
 cat <<'EOF107'> /etc/openvpn/server.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 1 (0x1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=CN, ST=CA, L=SanFrancisco, O=Fort-Funston, OU=www.dingd.cn, CN=Fort-Funston CA/name=EasyRSA/emailAddress=admin@dingd.cn
        Validity
            Not Before: Feb 21 03:37:44 2017 GMT
            Not After : Feb 19 03:37:44 2027 GMT
        Subject: C=CN, ST=CA, L=SanFrancisco, O=Fort-Funston, OU=www.dingd.cn, CN=server/name=EasyRSA/emailAddress=admin@dingd.cn
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:c2:9a:7b:9b:89:ba:d2:a1:4a:2d:a2:af:39:c5:
                    b5:74:21:f9:4f:7f:35:2c:40:6a:42:3f:ed:3c:cd:
                    94:cb:60:9f:d0:8f:47:cc:7f:3c:80:f7:ce:a5:f8:
                    68:e3:7c:70:d5:01:9e:e9:65:ac:ee:a8:42:13:54:
                    27:c2:a4:0a:fb:34:54:10:5f:cb:40:3a:50:02:fe:
                    8f:ea:c8:6e:83:c5:c9:e6:6c:0d:61:1b:4e:25:8f:
                    6e:d5:54:65:7e:fa:ab:b2:37:03:a2:ec:f9:aa:23:
                    7e:94:33:b9:8e:aa:93:15:d2:1e:83:8f:13:d3:5d:
                    82:32:da:48:28:95:10:3a:7f:54:e2:3c:63:86:a8:
                    89:0d:ac:c4:60:60:0b:d2:5f:f6:7e:e1:97:94:3a:
                    7d:63:8d:43:7d:17:25:20:97:e4:34:a4:ce:be:e5:
                    3f:ce:28:0f:c4:ac:9d:50:43:0c:0d:5e:12:ef:48:
                    91:9c:86:4a:da:52:e5:10:92:99:99:26:67:15:57:
                    a3:40:16:6a:8b:81:52:8f:a9:5d:44:4c:d2:e0:15:
                    cb:63:98:7f:c9:20:87:d8:18:57:9b:40:1d:36:07:
                    bf:8f:6f:5b:9c:87:fb:7a:d1:a0:cf:99:a7:08:3a:
                    1f:6f:48:f7:2f:7a:2f:83:52:f2:83:d6:2c:b6:6a:
                    a5:07
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            Netscape Cert Type: 
                SSL Server
            Netscape Comment: 
                Easy-RSA Generated Server Certificate
            X509v3 Subject Key Identifier: 
                DD:0A:E4:D7:5B:58:7E:02:DB:78:C8:DA:A0:3A:AB:55:26:AF:9C:ED
            X509v3 Authority Key Identifier: 
                keyid:20:5C:38:CF:25:8D:B7:7C:07:E2:7A:5E:3C:23:D7:78:8A:ED:F0:71
                DirName:/C=CN/ST=CA/L=SanFrancisco/O=Fort-Funston/OU=www.dingd.cn/CN=Fort-Funston CA/name=EasyRSA/emailAddress=admin@dingd.cn
                serial:92:F3:B8:59:84:A3:0C:8C

            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
            X509v3 Key Usage: 
                Digital Signature, Key Encipherment
    Signature Algorithm: sha256WithRSAEncryption
         5b:0d:ab:1d:da:23:74:2c:d9:62:a0:45:f2:bf:3f:b0:93:5b:
         b1:38:b3:91:bf:53:ed:6d:32:a8:f3:91:c6:3d:5d:13:d9:9c:
         79:f4:bd:8d:45:02:54:65:5a:8e:7b:fa:8c:64:4c:4d:3b:12:
         a3:f4:bb:b1:a2:8f:96:61:bb:d3:73:aa:c4:78:c6:8c:1b:d7:
         e0:f0:21:d3:f6:2d:b3:67:0d:a6:a1:04:4d:0b:52:4b:35:df:
         76:75:89:d0:98:9a:2c:cc:65:a7:e9:d9:a9:8e:78:4f:3a:60:
         ec:04:2f:3e:71:c3:7d:cd:5d:4a:50:0a:3f:2c:17:01:48:62:
         00:c0:9c:b7:46:5d:ea:f5:39:9c:91:2b:1b:4f:ef:e2:d1:9a:
         98:94:0f:47:41:ff:98:3f:ee:ee:2a:b2:d3:f0:3f:21:28:d8:
         77:3c:e4:9c:1c:13:b6:2d:b7:28:40:ec:4a:27:55:d2:37:cb:
         22:2d:a5:8d:f6:24:7a:bb:79:7f:99:73:af:12:f5:07:6f:b1:
         84:dc:1f:51:fa:73:f4:dc:b8:47:ab:0e:76:60:6e:a6:c1:54:
         0f:db:b8:0d:d4:09:9e:76:df:52:e1:16:db:c9:12:aa:ef:a5:
         32:58:26:0d:ec:01:8f:a8:91:8b:c3:4d:0a:5a:23:4e:7b:12:
         19:5b:63:5c
-----BEGIN CERTIFICATE-----
MIIFRTCCBC2gAwIBAgIBATANBgkqhkiG9w0BAQsFADCBqjELMAkGA1UEBhMCQ04x
CzAJBgNVBAgTAkNBMRUwEwYDVQQHEwxTYW5GcmFuY2lzY28xFTATBgNVBAoTDEZv
cnQtRnVuc3RvbjEVMBMGA1UECxMMd3d3LmRpbmdkLmNuMRgwFgYDVQQDEw9Gb3J0
LUZ1bnN0b24gQ0ExEDAOBgNVBCkTB0Vhc3lSU0ExHTAbBgkqhkiG9w0BCQEWDmFk
bWluQGRpbmdkLmNuMB4XDTE3MDIyMTAzMzc0NFoXDTI3MDIxOTAzMzc0NFowgaEx
CzAJBgNVBAYTAkNOMQswCQYDVQQIEwJDQTEVMBMGA1UEBxMMU2FuRnJhbmNpc2Nv
MRUwEwYDVQQKEwxGb3J0LUZ1bnN0b24xFTATBgNVBAsTDHd3dy5kaW5nZC5jbjEP
MA0GA1UEAxMGc2VydmVyMRAwDgYDVQQpEwdFYXN5UlNBMR0wGwYJKoZIhvcNAQkB
Fg5hZG1pbkBkaW5nZC5jbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AMKae5uJutKhSi2irznFtXQh+U9/NSxAakI/7TzNlMtgn9CPR8x/PID3zqX4aON8
cNUBnullrO6oQhNUJ8KkCvs0VBBfy0A6UAL+j+rIboPFyeZsDWEbTiWPbtVUZX76
q7I3A6Ls+aojfpQzuY6qkxXSHoOPE9NdgjLaSCiVEDp/VOI8Y4aoiQ2sxGBgC9Jf
9n7hl5Q6fWONQ30XJSCX5DSkzr7lP84oD8SsnVBDDA1eEu9IkZyGStpS5RCSmZkm
ZxVXo0AWaouBUo+pXURM0uAVy2OYf8kgh9gYV5tAHTYHv49vW5yH+3rRoM+Zpwg6
H29I9y96L4NS8oPWLLZqpQcCAwEAAaOCAXswggF3MAkGA1UdEwQCMAAwEQYJYIZI
AYb4QgEBBAQDAgZAMDQGCWCGSAGG+EIBDQQnFiVFYXN5LVJTQSBHZW5lcmF0ZWQg
U2VydmVyIENlcnRpZmljYXRlMB0GA1UdDgQWBBTdCuTXW1h+Att4yNqgOqtVJq+c
7TCB3wYDVR0jBIHXMIHUgBQgXDjPJY23fAfiel48I9d4iu3wcaGBsKSBrTCBqjEL
MAkGA1UEBhMCQ04xCzAJBgNVBAgTAkNBMRUwEwYDVQQHEwxTYW5GcmFuY2lzY28x
FTATBgNVBAoTDEZvcnQtRnVuc3RvbjEVMBMGA1UECxMMd3d3LmRpbmdkLmNuMRgw
FgYDVQQDEw9Gb3J0LUZ1bnN0b24gQ0ExEDAOBgNVBCkTB0Vhc3lSU0ExHTAbBgkq
hkiG9w0BCQEWDmFkbWluQGRpbmdkLmNuggkAkvO4WYSjDIwwEwYDVR0lBAwwCgYI
KwYBBQUHAwEwCwYDVR0PBAQDAgWgMA0GCSqGSIb3DQEBCwUAA4IBAQBbDasd2iN0
LNlioEXyvz+wk1uxOLORv1PtbTKo85HGPV0T2Zx59L2NRQJUZVqOe/qMZExNOxKj
9Luxoo+WYbvTc6rEeMaMG9fg8CHT9i2zZw2moQRNC1JLNd92dYnQmJoszGWn6dmp
jnhPOmDsBC8+ccN9zV1KUAo/LBcBSGIAwJy3Rl3q9TmckSsbT+/i0ZqYlA9HQf+Y
P+7uKrLT8D8hKNh3POScHBO2LbcoQOxKJ1XSN8siLaWN9iR6u3l/mXOvEvUHb7GE
3B9R+nP03LhHqw52YG6mwVQP27gN1Amedt9S4RbbyRKq76UyWCYN7AGPqJGLw00K
WiNOexIZW2Nc
-----END CERTIFICATE-----
EOF107
 cat <<'EOF113'> /etc/openvpn/server.key
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDCmnubibrSoUot
oq85xbV0IflPfzUsQGpCP+08zZTLYJ/Qj0fMfzyA986l+GjjfHDVAZ7pZazuqEIT
VCfCpAr7NFQQX8tAOlAC/o/qyG6DxcnmbA1hG04lj27VVGV++quyNwOi7PmqI36U
M7mOqpMV0h6DjxPTXYIy2kgolRA6f1TiPGOGqIkNrMRgYAvSX/Z+4ZeUOn1jjUN9
FyUgl+Q0pM6+5T/OKA/ErJ1QQwwNXhLvSJGchkraUuUQkpmZJmcVV6NAFmqLgVKP
qV1ETNLgFctjmH/JIIfYGFebQB02B7+Pb1uch/t60aDPmacIOh9vSPcvei+DUvKD
1iy2aqUHAgMBAAECggEBALmb9sGHQDWduM6GGHMV69f0f4IfZmvqlG7T4kbYHk9M
vaGCx4x43xBzSxpqMECpdET14sfiPmry+PLOlY3EQOUQKA3mEEoWVDJG8qWQvjfY
8pVgAfLYxFR21dOLR7MxC4pThphjRk3MxPI904ILl3Z8jrYURWiYC5LNN33djzj6
h/e7hnTSb3cFbCCoZlgfvVB2pj5zHGG3EDJ5mDv7UpHhHWmFhNd4XSFdpVWZAA9k
OzR429EhZDZsGJl2SItzbN14yZsUlxJbg5SH1BSTjEXnqBMRM/L/KQi72LkAqukY
ht8tJSd1KqqYgQ21WoryIp3/Y6A55rL6BHLUMXMZrkECgYEA4zh2zI2cRwfneTpF
56E/B017acZaBxFkV1BVZMfsQtm+PEB7sjfiWU1+MXtmrlkJUY4F2cBMPq3ZfyD2
sfUWkW++yrRT5yiuEoSFjWTsolmblg1I2mI0MKJkYFJtjyndmH5LMR/q6hkCsD5P
RDGd4ZrlKdm2VOIl1JjNWzhoZmkCgYEA20BsASiuzEejgEyyGp9rYltepgbIMGIa
Cjq09l4P2CXKtaN4+aNS4Z/xzA/XrIyFmHivvRPz+gX5uL139GlhyrubiUpz2tpz
nv4q9+iEs4q0Riql6s+0m/s/rmXcpX/KWfNLGrmT1hBtLIhaQlXcttvNeaAEmYY5
nl15zZzToe8CgYAEnj0r4yTt/Kcju594GbriNxzvBW0G/79+Vs+lgLq4kRxgtR7O
fHxJPF34O33WxVB/K9fKmTHzhC0LfGwHKegPhKnoDMo3xIflMHRWb1qv4gpbfmGg
rqZI5sQLgSFg64TpeIems/NeVqvLUTjjNe7ziuZld1tRVldWftSNqhPVIQKBgBt/
Ecx3aKyP0250r+Vs1s/H+6/Aq/x9YRylTiqTk1MdMjXjYXmVRQCsyWs5FWg7W0nK
4OdKiE9zzmSfxlptmOkO7CuknbD1sohfAc6DZ5kIrSEbmiE/mTvyn4LknW5X/22W
eHXKjkLLXpW2J/Onxv1bxYIaUllanwFAYdUqdNQbAoGAGuVxPsta5a3jmXApobI6
WTPIqw8se4yRofRg4PKZuIly2mSg3gszJg4wJJslb02TONPe4Fy60YScUaq7OHLn
wKKyJCKBpfRgCEBLQBBVVPjmUxK+7+CZ73WlGezX4o8mHjNPWgShw9FfZdgKhhb1
/ScnaqxXy6f66HrTWdr4jYE=
-----END PRIVATE KEY-----
EOF113
 cat <<'EOF13'> /etc/openvpn/dh.pem
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEAjPnxU4pwnQZMMzxZoTS2TtBftJVj54PMfdyMEP7LAJL5gsCLfI0r
rs/Oomq6RTGnmY4GQ6q0R1IzuQEVOw2P9CcSBvZnoXtIQN1q0a0C7tRlkjGhYPN+
FvKrUzxpK53ijXUu+qiNEyH07u21w6z7kPNfYhagT09PEhCehgrPy7gkFFKJi4iR
9KNBvaeVzuy+xgDdO+lOAXzzG76syxwKNY/g5hmMyPIofFZ3e2iGfHqbCZgWtqzS
kxUGsK7iG3wtcsWLzYIuq5Umc3yT6ZrNka7XXm99SmQMFp6n5zrCcLHWqJ3HuiHr
/SayPFjLM0zs4fX1ZWgJpVF3uLpbMBeWmwIBAg==
-----END DH PARAMETERS-----
EOF13

 wget -O /etc/rc.local "https://raw.githubusercontent.com/guardeumvpn/Qwer77/master/rc.local"
 chmod +x /etc/rc.local

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
 
ENABLE IPV4 AND IPV6
COMPLETE 1%
"
 echo ipv4 >> /etc/modules
 echo ipv6 >> /etc/modules
 sysctl -w net.ipv4.ip_forward=1
 sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
 sed -i 's/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf
 sysctl -p
 clear
 
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
http_access deny all
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

rm -f setup*
exit 1
