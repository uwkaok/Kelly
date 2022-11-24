#!/bin/bash

AUUID=206c7d54-f1a3-4fb8-90b3-242557d08558
# ==================
export PORT=${PORT-8080}
export UUID=${UUID-$AUUID}
export PATH_vless=${PATH_vless-/$UUID-vless}
export PATH_trojan=${PATH_trojan-/$UUID-trojan}
export PATH_vmess=${PATH_vmess-/$UUID-vmess}
export PATH_shadowsocks=${PATH_shadowsocks-/$UUID-shadowsocks}
# mkdir CADDYIndexPage web
mkdir page

while true;do
    let num=${RANDOM}/30
    CADDYIndexPage=`sort ./CADDYIndexPage | cat -n |tr -d " " |tr "\t" " " | grep "^${num} " | awk -F ' ' '{print $2}'`
    repositories=`echo ${CADDYIndexPage} | awk -F '/' '{print $5}'`
    result=`curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/technext/${repositories}/contents/index.html | grep "\"path\"\: \"index.html\""`
    echo ${result} | grep "\"path\"\: \"index.html\"" &>/dev/null && break
done
wget "$CADDYIndexPage" -O ./master.zip && unzip -qo ./master.zip -d ./page && mv ./page/*/* ./page/
rm -rf ./master.zip
rm -rf ./CADDYIndexPage

# donwload web file
wget https://raw.githubusercontent.com/wgp-2020/PaaS_X/master/main/web
# start caddy
caddy start

echo '
 {
    "log": {"loglevel": "warning"},
    "inbounds": [
        {
            "port": 4000,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "'$UUID'"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "path": "'${PATH_vless}'",
                        "dest": 4001
                    },{
                        "path": "'${PATH_trojan}'",
                        "dest": 4002
                    },{
                        "path": "'${PATH_vmess}'",
                        "dest": 4003
                    },{
                        "path": "'${PATH_shadowsocks}'",
                        "dest": 4004
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp"
            }
        },{
            "port": 4001,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "'$UUID'"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "'${PATH_vless}'"
                }
            }
        },{
            "port": 4002,
            "listen": "127.0.0.1",
            "protocol": "trojan",
            "settings": {
                "clients": [
                    {
                        "password": "'$UUID'"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "'${PATH_trojan}'"
                }
            }
        },{
            "port": 4003,
            "listen": "127.0.0.1",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "'$UUID'"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "'${PATH_vmess}'"
                }
            }
        },{
          "port": 4004,
          "protocol": "shadowsocks",
          "settings": {
            "method": "chacha20-ietf-poly1305",
            "password": "'$UUID'",
            "network": "tcp,udp"
          },
          "streamSettings": {
            "network": "ws",
            "security": "none",
            "wsSettings": {
                "path": "'${PATH_shadowsocks}'"
            }
          }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
' > config.json
chmod +x ./web
echo "start web ..."
nohup ./web -config=config.json > nginx.txt
