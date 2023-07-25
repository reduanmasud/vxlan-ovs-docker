FROM ubuntu

RUN apt-get update
RUN apt-get install -y net-tools
RUN apt-get install -y iproute2
RUN apt-get install -y iputils-ping

CMD ["sleep", "7200"]