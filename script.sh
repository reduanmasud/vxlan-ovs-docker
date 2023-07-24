#!/bin/bash

# ======= BASIC SETUP ======= #
# Set the color variable
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
# Clear the color after that
clear='\033[0m'
# ======= /BASIC SETUP ======= #

echo -e "${yellow}Your Currently DOWN port/interfaces: ${clear}"
ip a | grep DOWN

echo -e "${yellow}Do you want to set an IP to your VM's interface? ${clear}"
echo -e -n "${yellow}Type n if already ip is bind with interfaces else type y: ${clear} (y/n) "
read y_n

if [[ "$y_n" == "y" ]]; then

echo -e "${yellow}Two VM should be in same subnet. ${clear}"
echo -e -n "${yellow}Enter IP address with cidr ${clear} ${green}(ex. 192.68.56.5/21): ${clear}"
read -r vm_ip

echo -e -n "${yellow}Enter port/interface name ${clear} ${green}(ex. eth0, enp0s8..): ${clear}"
read -r vm_interface

echo -e "${yellow} Binding IP with the interface... ${clear}"
sudo ip addr add $vm_ip dev $vm_interface

echo -e "${yellow} Setting the interface UP ${clear}"
sudo ip link set $vm_interface up mtu 1500

echo -e "${yellow} Done. ${clear}"
fi

# ========== [Enter] Continue ========== #
echo -e -n "Press ${yellow}Enter${clear} to continue ..."
read -r garrbage
# ========== [Enter] Continue ========== #


echo -e "${yellow} Updating linux repo apt. ${clear}"
sudo apt update

echo -e "${yellow} Installing necessery tools. ${clear}"
sudo apt install -y net-tools docker.io openvswitch-switch

# ========== [Enter] Continue ========== #
echo -e -n "Press ${yellow}Enter${clear} to continue ..."
read -r garrbage
# ========== [Enter] Continue ========== #

echo -e "${yellow}Now we will create bridge and set port/interface internal type${clear}"
echo -e -n "${green}Enter first bridge name (Ex. ovs-br0): ${clear}"
read -r br1_name
echo -e "${green}Creaing Bridge... ${clear}"
sudo ovs-vsctl add-br $br1_name
echo -e "${green}Setting up Brideg... ${clear}"
sudo ovs-vsctl add-port $br1_name veth0 -- set interface veth0 type=internal


echo -e -n "${green}Enter Second bridge name (Ex. ovs-br1): ${clear}"
read -r br2_name
echo -e "${green}Creaing Bridge... ${clear}"
sudo ovs-vsctl add-br $br2_name
echo -e "${green}Setting up Brideg... ${clear}"
sudo ovs-vsctl add-port $br2_name veth1 -- set interface veth1 type=internal

show ovs-vsctl show

# ========== [Enter] Continue ========== #
echo -e -n "Press ${yellow}Enter${clear} to continue ..."
read -r garrbage
# ========== [Enter] Continue ========== #


echo -e "${yellow}Setting ip address to each port/interface ${clear}"
echo -e -n "${green}Enter IP for veth0 (ex. 192.168.1.1/24): ${clear}"
read -r veth0_ip

echo -e "${green}Setting ip...${clear}"
sudo ip addr add $veth0_ip dev veth0
echo -e "${green}Make interface UP ...${clear}"
sudo ip link set dev veth0 up mtu 1500

echo -e -n "${green}Enter IP for veth1 (ex. 192.168.2.1/24): ${clear}"
read -r veth1_ip

ip a | grep DOWN

echo -e "${green}Setting ip...${clear}"
sudo ip addr add $veth1_ip dev veth0
echo -e "${green}Make interface UP ...${clear}"
sudo ip link set dev veth1 up mtu 1500

ip a

# ========== [Enter] Continue ========== #
echo -e -n "Press ${yellow}Enter${clear} to continue ..."
read -r garrbage
# ========== [Enter] Continue ========== #


# create image from Dockerfile and create container with none

echo -e "${yellow}Building docker image from docker image ${clear}"
sudo docker build . -t ubuntu-docker

echo -e "${yellow}Now we will create container from the build image ${clear}"
echo -e "${yellow}These will be different for VM1 & VM2 ${clear}"

echo -e -n "${green}Enter first container name (ex. docker1): ${clear}"
read -r docker1_name

sudo docker run -d --net=none --name $docker1_name ubuntu-docker

echo -e -n "${green}Enter Second container name (ex. docker2): ${clear}"
read -r docker2_name

sudo docker run -d --net=none --name $docker2_name ubuntu-docker

sudo docker ps


# ========== [Enter] Continue ========== #
echo -e -n "Press ${yellow}Enter${clear} to continue ..."
read -r garrbage
# ========== [Enter] Continue ========== #

echo -e "${yellow}COMMAND ip a @ $docker1_name ${clear}"
sudo docker exec $docker1_name ip a

echo -e "${yellow}COMMAND ip a @ $docker2_name ${clear}"
sudo docker exec $docker2_name ip a

# ========== [Enter] Continue ========== #
echo -e -n "Press ${yellow}Enter${clear} to continue ..."
read -r garrbage
# ========== [Enter] Continue ========== #


echo -e "${yellow}Now we will assign static ip address to containers ${clear}"

echo -e -n "${green}Enter IP address for First container(ex. 192.168.1.11/24): ${clear}"
read -r docker1_ip
echo -e -n "${green}Enter Gateway address for First container (ex. 192.168.1.1): ${clear}"
read -r docker1_gateway

sudo ovs-docker add-port $br1_name eth0 $docker1_name --ipaddress=$docker1_ip --gateway=$docker1_gateway
sudo docker exec $docker1_name ip a

# ========== [Enter] Continue ========== #
echo -e -n "Press ${yellow}Enter${clear} to continue ..."
read -r garrbage
# ========== [Enter] Continue ========== #

echo -e -n "${green}Enter IP address for Second container(ex. 192.168.2.11/24): ${clear}"
read -r docker2_ip
echo -e -n "${green}Enter Gateway address for Second container (ex. 192.168.2.1): ${clear}"
read -r docker2_gateway

sudo ovs-docker add-port $br2_name eth0 $docker2_name --ipaddress=$docker2_ip --gateway=$docker2_gateway
sudo docker exec $docker2_name ip a

# ========== [Enter] Continue ========== #
echo -e -n "Press ${yellow}Enter${clear} to continue ..."
read -r garrbage
# ========== [Enter] Continue ========== #


echo -e "${yellow} $docker1_name Ping Test.. ${clear}"
sudo docker exec $docker1_name ping $docker1_gateway -c 4

# ========== [Enter] Continue ========== #
echo -e -n "Press ${yellow}Enter${clear} to continue ..."
read -r garrbage
# ========== [Enter] Continue ========== #


echo -e "${yellow} $docker2_name Ping Test.. ${clear}"
sudo docker exec $docker2_name ping $docker2_gateway -c 4

# ========== [Enter] Continue ========== #
echo -e -n "Press ${yellow}Enter${clear} to continue ..."
read -r garrbage
# ========== [Enter] Continue ========== #

# one thing to check; as vxlan communicate using udp port 4789, check the current status
echo -e "${yellow}check the current status${clear}"
netstat -ntulp

# Create the vxlan tunnel using ovs vxlan feature for both bridges to another hosts bridges
# make sure remote IP and key options; they are important
echo -e "${yellow}Create the vxlan tunnel using ovs vxlan feature for both bridges to another hosts bridges${clear}"

echo -e "${green} => For $br1_name {$clear}"
echo -e -n "${green}Enter other VM IP:${clear}"
read -r other_vm_ip

echo -e -n "${green}ENTER VNI Key:${clear}"
read -r vni_key

sudo ovs-vsctl add-port $br1_name vxlan0 -- set interface vxlan0 type=vxlan options:remote_ip=$other_vm_ip options:key=$vni_key

echo -e "${green} => For $br2_name {$clear}"
echo -e -n "${green}Enter other VM IP:${clear}"
read -r other_vm_ip

echo -e -n "${green}ENTER VNI Key:${clear}"
read -r vni_key

sudo ovs-vsctl add-port $br2_name vxlan1 -- set interface vxlan1 type=vxlan options:remote_ip=$other_vm_ip options:key=$vni_key

# check the port again; it should be listening
netstat -ntulp | grep 4789

sudo ovs-vsctl show

ip a

# ========== [Enter] Continue ========== #
echo -e -n "Press ${yellow}Enter${clear} to continue ..."
read -r garrbage
# ========== [Enter] Continue ========== #


echo -e "${yellow} Finishing setup ${clear}"
# ping the outer world, should not reach the internet
ping 1.1.1.1 -c 2

# Now let's make NAT Conncetivity for recahing the internet

sudo cat /proc/sys/net/ipv4/ip_forward

# enabling ip forwarding by change value 0 to 1
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -p /etc/sysctl.conf
sudo cat /proc/sys/net/ipv4/ip_forward

# see the rules
sudo iptables -t nat -L -n -v

sudo iptables --append FORWARD --in-interface veth1 --jump ACCEPT
sudo iptables --append FORWARD --out-interface veth1 --jump ACCEPT
sudo iptables --table nat --append POSTROUTING --source 192.168.2.0/24 --jump MASQUERADE

# ping the outer world now, should be working now
ping 1.1.1.1 -c 2