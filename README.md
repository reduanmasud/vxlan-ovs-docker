# vxlan-ovs-docker

## Diagram

![OVS Diagram](https://github.com/reduanmasud/vxlan-ovs-docker/blob/main/vxlan-ovs-docker.png)

## Overview what are we going to do

1. Create two VMs.
2. Configure those VMs interfaces so that both are in same subnet
3. Install the necessary tools
4. Create two OVS bridges.
5. Add port interfaces to those bridges
6. Set IP to those bridge's interfaces. `keep in mind: these ip will act as gateway`
7. make UP the bridges and set an mtu (maximum transmission unit)
8. Create two docker container with `none` net `we will configure net later`
9. Assign `ip address` and `gateway` to these containers.
10. Configure vxlan with brige
11. Need some finish up work to make connection with the internet

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
sudo apt-get update
sudo apt-get install -y net-tools docker.io openvswitch-switch
```

## Create Two Bride using `ovs-vsctl` utility tools

**VM Host 01**
```sh
# Create a bridge named 'ovs-br0'
sudo ovs-vsctl add-br ovs-br0

# Create a bridge named 'ovs-br1'
sudo ovs-vsctl add-br ovs-br1
```

**VM Host 02**
```sh
# Create a bridge named 'ovs-br0'
sudo ovs-vsctl add-br ovs-br0

# Create a bridge named 'ovs-br1'
sudo ovs-vsctl add-br ovs-br1
```
**NB:** Bridge name should be same in both VMs.

## create the internal port/interfaces to the ovs-bridge:

**Both VMs**
```sh
# add port/interfaces to bridges
sudo ovs-vsctl add-port ovs-br0 veth0 -- set interface veth0 type=internal
sudo ovs-vsctl add-port ovs-br1 veth1 -- set interface veth1 type=internal
# ovs-br0 is the bridge name
# veth0 is the interface/port name where type is 'internal'

# check the status of bridges
sudo ovs-vsctl show

```
**Explanation:** `sudo ovs-vsctl add-port ovs-br0 veth0 -- set interface veth0 type=internal`

**ovs-vsctl:** This is the command-line utility for managing Open vSwitch (OVS) configurations.

**add-port ovs-br0 veth0:** This part of the command adds a new port named veth0 to the OVS bridge named ovs-br0. In OVS, bridges are virtual switches that can connect multiple interfaces together, allowing communication between different ports.

**--:** This double dash -- separates the add-port command from the following set command, indicating that the options specified after this point are for the set command, not the add-port command.

**set interface veth0 type=internal:** This sets the newly added port veth0 as an internal interface. An internal interface in OVS is a special type of virtual interface that is used for communication between different ports within the same OVS bridge.

## Set the IP of the bridges and up the interface:

**Both VMs** `Two VM bridges should have same IP address as they will work as gateway`

```sh
# set the ip to the created port/interfaces
sudo ip address add 192.168.1.1/24 dev veth0 
sudo ip address add 192.168.2.1/24 dev veth1

# Check the status, link should be down
ip a

# up the interfaces and check status
sudo ip link set dev veth0 up mtu 1450
sudo ip link set dev veth1 up mtu 1450

# Check the status, link should be UP/UNKNOWN 
ip a
```
## Create two docker container with `none` net

**VM Host 01**
```sh
# create a docker image from the docker file 
# find the Dockerfile in the repo
sudo docker build . -t ubuntu-docker

# create containers from the created image; Containers not connected to any network
sudo docker run -d --net=none --name docker1 ubuntu-docker
sudo docker run -d --net=none --name docker2 ubuntu-docker
```
**Here `docker1` and `docker2` is the name of docker container and `ubuntu-docker` is the name of the image we have built.**

**VM Host 02**
```sh
# create a docker image from the docker file 
# find the Dockerfile in the repo
sudo docker build . -t ubuntu-docker

# create containers from the created image; Containers not connected to any network
sudo docker run -d --net=none --name docker3 ubuntu-docker
sudo docker run -d --net=none --name docker4 ubuntu-docker
```
**Here `docker3` and `docker4` is the name of docker container and `ubuntu-docker` is the name of the image we have built.**

## Assign IP and Gateway to these containers

**VM Host 01**
```sh
# add ip address to the container using ovs-docker utility 
sudo ovs-docker add-port ovs-br0 eth0 docker1 --ipaddress=192.168.1.11/24 --gateway=192.168.1.1
sudo docker exec docker1 ip a

sudo ovs-docker add-port ovs-br1 eth0 docker2 --ipaddress=192.168.2.11/24 --gateway=192.168.2.1
sudo docker exec docker2 ip a

# ping the gateway to check if container connected to ovs-bridges
sudo docker exec docker1 ping 192.168.1.1
sudo docker exec docker2 ping 192.168.2.1
```

**VM Host 02**
```sh
# add ip address to the container using ovs-docker utility 
sudo ovs-docker add-port ovs-br0 eth0 docker1 --ipaddress=192.168.1.12/24 --gateway=192.168.1.1
sudo docker exec docker1 ip a

sudo ovs-docker add-port ovs-br1 eth0 docker2 --ipaddress=192.168.2.12/24 --gateway=192.168.2.1
sudo docker exec docker2 ip a

# ping the gateway to check if container connected to ovs-bridges
sudo docker exec docker1 ping 192.168.1.1
sudo docker exec docker2 ping 192.168.2.1
```

**Explanation:** `sudo ovs-docker add-port ovs-br1 eth0 docker2 --ipaddress=192.168.2.12/24 --gateway=192.168.2.1`
**ovs-docker:** This is a command-line utility used to manage the integration between Docker containers and Open vSwitch bridges.

**add-port ovs-br1 eth0 docker2:** This part of the command adds the physical network interface eth0 from the Docker container docker2 to the OVS bridge named ovs-br1. By doing this, the container's network traffic will be routed through the OVS bridge, allowing connectivity to other containers or external networks connected to the bridge.

**--ipaddress=192.168.2.12/24:** This option assigns the IP address 192.168.2.12 with a subnet mask of 24 (equivalent to a netmask of 255.255.255.0) to the eth0 interface of docker2. This IP address is in the range of the 192.168.2.0 subnet.

**--gateway=192.168.2.1:** This option specifies the default gateway IP address 192.168.2.1 for the container. The default gateway is used as the exit point for traffic originating from the container that is destined for networks outside the local subnet.

## Establish the VXLAN TUNNELING

**VM Host 01**
```bash
# one thing to check; as vxlan communicate using udp port 4789, check the current status
netstat -ntulp

# Create the vxlan tunnel using ovs vxlan feature for both bridges to another hosts bridges
sudo ovs-vsctl add-port ovs-br0 vxlan0 -- set interface vxlan0 type=vxlan options:remote_ip=192.68.56.3 options:key=1000
sudo ovs-vsctl add-port ovs-br1 vxlan1 -- set interface vxlan1 type=vxlan options:remote_ip=192.68.56.3 options:key=2000

# check the port again; it should be listening
netstat -ntulp | grep 4789

sudo ovs-vsctl show

ip a
```

**VM Host 02**
```bash
# one thing to check; as vxlan communicate using udp port 4789, check the current status
netstat -ntulp

# Create the vxlan tunnel using ovs vxlan feature for both bridges to another hosts bridges
sudo ovs-vsctl add-port ovs-br0 vxlan0 -- set interface vxlan0 type=vxlan options:remote_ip=192.68.56.2 options:key=1000
sudo ovs-vsctl add-port ovs-br1 vxlan1 -- set interface vxlan1 type=vxlan options:remote_ip=192.68.56.2 options:key=2000

# check the port again; it should be listening
netstat -ntulp | grep 4789

sudo ovs-vsctl show

ip a
```

**Explanation:** 

**ovs-vsctl:** This is the command-line utility for managing Open vSwitch (OVS) configurations.

**add-port ovs-br0 vxlan0:** This part of the command adds a new port named vxlan0 to the OVS bridge named ovs-br0. In this context, vxlan0 is a virtual port that represents a VXLAN tunnel endpoint on the OVS bridge.

**--:** This double dash -- separates the add-port command from the following set command, indicating that the options specified after this point are for the set command, not the add-port command.

**set interface vxlan0 type=vxlan:** This sets the interface type of vxlan0 to VXLAN. By specifying type=vxlan, we indicate that this interface will be used to establish a VXLAN tunnel.

**options:remote_ip=192.68.56.3:** This option specifies the remote IP address for the VXLAN tunnel. The VXLAN packets will be encapsulated and sent to the remote IP address 192.68.56.3, which represents the destination VXLAN tunnel endpoint.

**options:key=1000:** This option sets the VXLAN Network Identifier (VNI) to 1000. The VNI is used to segment traffic within the VXLAN network, allowing multiple isolated virtual networks to coexist on the same physical network infrastructure. VXLAN tunnels with the same VNI value can communicate with each other as if they were on the same LAN segment, even if they are physically distributed across different network nodes.

`The command creates a new VXLAN tunnel port named vxlan0 and adds it to the OVS bridge ovs-br0. The VXLAN tunnel will be used to encapsulate and forward network traffic between the local OVS bridge and the remote IP address 192.68.56.3, using the specified VNI value of 1000 for segmentation.`


## Now Let's give it a try
```bash

# FROM docker1
# will get ping 
sudo docker exec docker1 ping 192.168.1.12
sudo docker exec docker1 ping 192.168.1.11

# will be failed
sudo docker exec docker1 ping 192.168.2.11
sudo docker exec docker1 ping 192.168.2.12

# FROM docker2
# will get ping 
sudo docker exec docker2 ping 192.168.2.11
sudo docker exec docker2 ping 192.168.2.12

# will be failed
sudo docker exec docker2 ping 192.168.1.11
sudo docker exec docker2 ping 192.168.1.12

```
`successful pings are expected when communicating within the same subnet, and ping failures are expected when trying to communicate across different subnets, as there is no routing or connectivity established between the subnets`



