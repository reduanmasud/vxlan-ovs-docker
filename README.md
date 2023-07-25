# vxlan-ovs-docker

## Diagram

![OVS Diagram](https://github.com/reduanmasud/vxlan-ovs-docker/blob/main/vxlan-ovs-docker.png)

## Overview what are we going to do

1. Create two VM
2. Configure those VMs interface so that both are in same subnet
3. Install necessery tools
4. Create two ovs bridge
5. Add port-interface to those bridges
6. Set IP to those bridge's interface `keep in mind: these ip will act as gateway`
7. make UP the bridges and set an mtu (maximum transmission unit)
8. Create two docker container wint `none` net `we will configure net later`
9. Configure vxlan with brige
10. Need some finish up work to make connection with the internet
