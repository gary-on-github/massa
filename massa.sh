#!/bin/bash
# Version 0.0.1

curl -s https://raw.githubusercontent.com/testnets-io/core/main/logo.sh | bash # grab testnets.io ascii logo

sleep 1

CHOICE=$(
whiptail --title "Massa Manager" --menu "Make a Choice" 25 78 16 \
	"1" "Node Installation."   \
	"2" "Start Client." \
  "3" "Start Node Service." \
  "4" "Stop Node Service." \
  "5" "Create Wallet. - Only run once" \
  "6" "View wallet." \
  "7" "Check Journalctl." \
	"8" "End script"  3>&2 2>&1 1>&3	
)

clear 

curl -s https://raw.githubusercontent.com/testnets-io/core/main/logo.sh | bash # grab testnets.io ascii logo

case $CHOICE in

1) # 1 - NODE INSTALLATION
sudo apt update -y && sudo apt upgrade -y < "/dev/null"
sudo apt install curl make clang pkg-config libssl-dev build-essential git mc jq unzip wget -y
cd "$HOME" || exit
wget https://github.com/massalabs/massa/releases/download/TEST.8.0/massa_TEST.8.0_release_linux.tar.gz
tar -xvf massa_TEST*

sudo tee <<EOF >/dev/null /etc/systemd/system/massa.service
[Unit]
Description=Massa Node Service
After=network-online.target
[Service]
Environment=RUST_BACKTRACE=full
User=$USER
Restart=always
RestartSec=3
LimitNOFILE=65535
WorkingDirectory=$HOME/massa/massa-node
ExecStart=$HOME/massa/massa-node/massa-node
[Install]
WantedBy=multi-user.target
EOF

sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF

sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable massa

echo "Adding firewall rules"  
sudo ufw allow 31244  
sudo ufw allow 31245 
sudo ufw allow 22
sudo ufw --force enable
;;

ipv6=$(ip -6 addr | grep inet6 | awk -F '[ \t]+|/' '{print $3}' | grep -v ^::1 | grep -v ^fe80)
sudo tee -a <<EOF >/dev/null "$HOME"/massa/massa-node/config/config.toml
[network]
# replace the ip with yours
routable_ip ="$ipv6"
max_ping = 10000
# target number of non bootstrap outgoing connections
target_out_nonbootstrap_connections = 6
# max number of inbound non bootstrap connections
max_in_nonbootstrap_connections = 9

[bootstrap]
# list of bootstrap (ip, node id)
bootstrap_list = [["149.202.86.103:31245", "5GcSNukkKePWpNSjx9STyoEZniJAN4U4EUzdsQyqhuP3WYf6nj"],
    ["149.202.89.125:31245", "5wDwi2GYPniGLzpDfKjXJrmHV3p1rLRmm4bQ9TUWNVkpYmd4Zm"],
    ["158.69.120.215:31245", "5QbsTjSoKzYc8uBbwPCap392CoMQfZ2jviyq492LZPpijctb9c"],
    ["158.69.23.120:31245", "8139kbee951YJdwK99odM7e6V3eW7XShCfX5E2ovG3b9qxqqrq"],
    ["93.29.134.115:31245", "7hx5EnXjTBWUvqDtVuEzyiQQTdNY6zycDi7GVxr7AqZ19Rzg9o"]]
# refuse consecutive bootstrap attempts from a given IP when the interval between them is lower than per_ip_min_interval milliseconds
per_ip_min_interval = 3600000

EOF
echo "Community bootstrap ip addresses added"


2) # 2 - START CLIENT
cd $HOME/massa/massa-client/
./massa-client
;;

3) # 3 - START NODE SERVICE
sudo systemctl start massa
;;

4) # 4 - STOP NODE SERVICE
sudo systemctl stop massa
;;

5) # 5 - CREATE WALLET 
cd $HOME/massa/massa-client/
./massa-client --wallet wallet.dat wallet_generate_private_key
;;

6) # 6 - VIEW WALLET
cd $HOME/massa/massa-client/
./massa-client -- wallet_info
;;

7) # 7 - CHECK JOURNALCTL
sudo journalctl -eu massa.service
;;

8) # 8 - EXIT
exit
;;



*) echo "Not an option";;
esac
