# vxlan-ovs-docker

## Diagram

![OVS Diagram](https://github.com/reduanmasud/vxlan-ovs-docker/blob/main/vxlan-ovs-docker.png)

## Overview what are we going to do

1. Create two VMs.
2. Configure those VMs interfaces so that both are in same subnet
3. Install the necessary tools
4. Create two OVS bridge
5. Add port interfaces to those bridges
6. Set IP to those bridge's interfaces. `keep in mind: these ip will act as gateway`
7. make UP the bridges and set an mtu (maximum transmission unit)
8. Create two docker container wint `none` net `we will configure net later`
9. Configure vxlan with brige
10. Need some finish up work to make connection with the internet

## Creating  two VMs
Install VirtualBox and create two VMs in that virtual box. In my case, I am using `ubuntu-server 18.0` Now We need to add extra interface adapter to our VMs

1. We need to create a network. To do that, go to **Settings > Network > Host Only Network** Now click **Create**
2. You will find something like `vboxnet0, vboxnet1 ...`
3. Go to each VMs **Settings > Network > Adapter 2:** Now Set, **Attatched to:** `Host Only Network` And **Name:** `vboxnet0`

## Assign IP address from the same subnet to newly created VMs
1. Start both VMs and check there `ip a` status
```sh
# Check all interfaces that are down. Where we can assign ip address
ip a | grep DOWN
```
You will see like this:
```sh
enp0s8: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc fq_codel state DOWN group default qlen 1000
# ^^^^
# this is the name of our interface, it can be **eth0**, **eno1** or anything else
```
2. Assign IP

**VM Host 01**
```sh
sudo ip addr add 192.68.56.2/21 dev enp0s8
sudo ip link set enp0s8 up
```
**VM Host 02**
```sh
sudo ip addr add 192.68.56.3/21 dev enp0s8
sudo ip link set enp0s8 up
```
Now you can check agaig using `ip a` is every thing is ok.

## Install Necessery tools
**Both VMs**
```sh
sudo apt update
sudo apt install -y net-tools docker.io
```
